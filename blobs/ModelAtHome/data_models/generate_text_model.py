from pydantic import BaseModel


class PostGenerateText(BaseModel):
    query: str = "Nyanpasu!"
    preprompt: str = None
    context1: list = None
    context2: list[str] = None
    seed: int = 0
    max_new_tokens: int = 256
    temperature: float = 1.0
    top_k: int = 50
    top_p: float = 1.0
    min_p: float = 0.05
    do_sample: bool = False
    typical_p: float = 1.0
    repetition_penalty: float = 1.0


class ReturnGeneratedText(BaseModel):
    context1: str = ""
    context2: str = ""
    query: str = ""
    generated_text: str = ""
    seed: int = 0
