import torch, gc, asyncio, os
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from transformers.utils import (
    is_flash_attn_2_available,
)  # https://github.com/Dao-AILab/flash-attention
from sentence_transformers import SentenceTransformer
from functools import partial
from data_models.chat_room import ChatRoom
from data_models.generate_text_model import PostGenerateText, ReturnGeneratedText
from enum import Enum
from huggingface_hub import snapshot_download


class ModelType(Enum):
    LLM = 1
    EMBEDDING = 2


class Model:
    loading_text = "Loading/Downloading Model"
    def __init__(self):
        self.device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        self.llm_model: AutoModelForCausalLM = None
        self.embedding_model: SentenceTransformer = None
        self.llm_model_id = ""
        self.embedding_model_id = ""
        self.chat_room = ChatRoom(self.device)

    def unload_model(self, model_type: ModelType):
        if model_type is ModelType.EMBEDDING:
            if self.embedding_model is not None:
                del self.embedding_model
            self.embedding_model: SentenceTransformer = None
            self.chat_room.set_embedding_model(self.embedding_model)
            self.embedding_model_id = ""
        elif model_type is ModelType.LLM:
            if self.llm_model is not None:
                del self.llm_model
            self.llm_model: AutoModelForCausalLM = None
            self.llm_model_id = ""
        gc.collect()
        torch.cuda.empty_cache()
        return True

    def load_model_executor(self, model_type: ModelType, model_id: str):        
        model_path =  self.get_model(model_type, model_id)

        if model_type is ModelType.EMBEDDING:
            if self.embedding_model is not None:
                self.unload_model(ModelType.EMBEDDING)
            self.embedding_model_id=Model.loading_text
            self.embedding_model = SentenceTransformer(
                model_name_or_path=model_path, device=self.device
            )
            self.chat_room.set_embedding_model(self.embedding_model)
            self.embedding_model_id = model_id
        elif model_type is ModelType.LLM:
            if self.llm_model is not None:
                self.unload_model(ModelType.LLM)
            self.llm_model_id=Model.loading_text
            quantization_config = BitsAndBytesConfig(
                load_in_4bit=True,
                bnb_4bit_compute_dtype=torch.float16,
                llm_int8_enable_fp32_cpu_offload=True,
            )

            if is_flash_attn_2_available():
                self.attn_implementation = "flash_attention_2"
            else:
                self.attn_implementation = "sdpa"

            self.tokenizer = AutoTokenizer.from_pretrained(model_path)
            self.llm_model = AutoModelForCausalLM.from_pretrained(
                model_path,
                torch_dtype=torch.float16,
                quantization_config=quantization_config,
                attn_implementation=self.attn_implementation,
            )
            self.llm_model_id = model_id
        return True
    
    async def load_model(self, model_type: ModelType, model_id: str):
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(
            None, partial(self.load_model_executor, model_type, model_id)
        )

    def generate_text_executor(
        self,
        data: PostGenerateText,
        return_generated_text: ReturnGeneratedText,
    ):
        return_generated_text.query = data.query
        prompt = (
            data.prompt
            if data.prompt
            else self.chat_room.build_prompt(data.query, return_generated_text)
        )
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
        return_generated_text.generated_text = response

    async def generate_text(self, data: PostGenerateText) -> ReturnGeneratedText:
        return_generated_text = ReturnGeneratedText()
        if self.llm_model is None:
            return_generated_text.query = data.query
            return_generated_text.generated_text = "model is not loaded"  
        else:          
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(
                None, partial(self.generate_text_executor, data, return_generated_text)
            )
        return return_generated_text

    def build_context(self, data: PostGenerateText):
        query = data.query
        return_generated_text = ReturnGeneratedText()
        return_generated_text.query = query
        value = self.chat_room.build_context(query, return_generated_text)
        print(f"Builded context: {value}")
        return value

    def get_model(self, model_type: ModelType, model_id: str) -> str:
        model_path = f"./models/{model_type.name.lower()}/{model_id}/"
        if not os.path.exists(model_path):
            snapshot_download(repo_id=model_id, local_dir=model_path)
        return model_path

    def get_model_list():
        llm = ModelType.LLM.name
        embedding = ModelType.EMBEDDING.name
        llm_dir = f"./models/{llm}/"
        if not os.path.exists(llm_dir):
            os.makedirs(llm_dir)
        embedding_dir = f"./models/{embedding}/"
        if not os.path.exists(embedding_dir):
            os.makedirs(embedding_dir)
        llm_list = []
        embedding_list = []
        for provider in os.listdir(llm_dir):
            for item in os.listdir(os.path.join(llm_dir, provider)):
                llm_list.append(f"{provider}/{item}")
        for provider in os.listdir(embedding_dir):
            for item in os.listdir(os.path.join(embedding_dir, provider)):
                embedding_list.append(f"{provider}/{item}")
        return {
            llm: llm_list,
            embedding: embedding_list,
        }
