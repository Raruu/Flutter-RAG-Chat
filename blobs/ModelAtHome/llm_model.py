import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
from transformers.utils import (
    is_flash_attn_2_available,
)  # https://github.com/Dao-AILab/flash-attention
from request_data_model import RequestData
import gc


class Model:
    def __init__(self, model_id):
        self.device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        self.load_model(model_id)

    def load_model(self, model_id):
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
        input_ids = self.tokenizer(data.prompt, return_tensors="pt").input_ids.to(
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
        return self.tokenizer.decode(output[0], skip_special_tokens=True).replace(
            data.prompt, ""
        ).strip()
