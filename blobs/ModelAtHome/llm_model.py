import torch, gc
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from transformers.utils import (
    is_flash_attn_2_available,
)  # https://github.com/Dao-AILab/flash-attention
from data_models.request_data_model import RequestData
from sentence_transformers import SentenceTransformer
from data_models.chat_room import ChatRoom


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

    def generate_text(self, data: RequestData) -> str:
        prompt = self.chat_room.build_prompt(data.query)
        print(f"Builded prompt: {prompt}")
        input_ids = self.tokenizer(prompt, return_tensors="pt").input_ids.to(
            self.device
        )
        output = self.llm_model.generate(
            input_ids,
            max_new_tokens=data.max_new_tokens,
            temperature=data.temperature,
            top_k=data.top_k,
            top_p=data.top_p,
            min_p=data.min_p,
            do_sample=data.do_sample,
            typical_p=data.typical_p,
            repetition_penalty=data.repetition_penalty,
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
        return response
