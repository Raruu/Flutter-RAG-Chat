import torch, gc, asyncio
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from transformers.utils import (
    is_flash_attn_2_available,
)  # https://github.com/Dao-AILab/flash-attention
from sentence_transformers import SentenceTransformer
from functools import partial

from data_models.chat_room import ChatRoom
from data_models.generate_text_model import PostGenerateText, ReturnGeneratedText

class Model:
    def __init__(self, model_id: str):
        self.device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        self.load_model(model_id)
        self.chat_room = ChatRoom(self.device, self.embedding_model)

    def load_model(self, model_id: str):
        # EMBEDDING
        self.embedding_model = SentenceTransformer(
            model_name_or_path="all-mpnet-base-v2", device=self.device
        )

        # LLM
        quantization_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_compute_dtype=torch.float16,
            llm_int8_enable_fp32_cpu_offload=True,
        )

        if is_flash_attn_2_available():
            self.attn_implementation = "flash_attention_2"
        else:
            self.attn_implementation = "sdpa"

        self.tokenizer = AutoTokenizer.from_pretrained(model_id)
        self.llm_model = AutoModelForCausalLM.from_pretrained(
            model_id,
            torch_dtype=torch.float16,
            quantization_config=quantization_config,
            attn_implementation=self.attn_implementation,
        )

    def generate_text_executor(
        self,
        input_ids,
        max_new_tokens,
        temperature,
        top_k,
        top_p,
        min_p,
        do_sample,
        typical_p,
        repetition_penalty,
    ):
        return self.llm_model.generate(
            input_ids,
            max_new_tokens=max_new_tokens,
            temperature=temperature,
            top_k=top_k,
            top_p=top_p,
            min_p=min_p,
            do_sample=do_sample,
            typical_p=typical_p,
            repetition_penalty=repetition_penalty,
        )

    async def generate_text(self, data: PostGenerateText) -> ReturnGeneratedText:
        return_generated_text = ReturnGeneratedText()
        return_generated_text.query = data.query
        prompt = self.chat_room.build_prompt(data.query, return_generated_text)
        print(f"Builded prompt: {prompt}")
        input_ids = self.tokenizer(prompt, return_tensors="pt").input_ids.to(
            self.device
        )
        loop = asyncio.get_running_loop()
        output = await loop.run_in_executor(
            None,
            partial(
                self.generate_text_executor,
                input_ids,
                data.max_new_tokens,
                data.temperature,
                data.top_k,
                data.top_p,
                data.min_p,
                data.do_sample,
                data.typical_p,
                data.repetition_penalty,
            ),
        )
        del input_ids
        gc.collect()
        torch.cuda.empty_cache()
        response = (
            self.tokenizer.decode(output[0], skip_special_tokens=True)
            .replace(prompt, "")
            .strip()
        )
        self.chat_room.update_chat_history(data.query, response)
        return_generated_text.generated_text = response
        return return_generated_text
