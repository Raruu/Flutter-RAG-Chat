from pydantic import BaseModel
class Data(BaseModel):
    prompt: str = 'Nyanpasu!'
    max_new_tokens: int = 256
    temperature: float = 1.0
    top_k: int = 50
    top_p: float = 1.0
    min_p: float = 0.05
    do_sample: bool = False
    typical_p: int = 1
    repetition_penalty: float = 1.0