from pydantic import BaseModel
class PostSetChatRoomModel(BaseModel):
    id: str
    use_preprompt: bool
    preprompt: str
    use_chat_history: bool
    chat_history: list