from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from llm_model import Model
import os

from data_models.generate_text_model import PostGenerateText, ReturnGeneratedText
from data_models.information_model import InfomationData
from data_models.post_set_chatroom_model import PostSetChatRoomModel

# Put Your Model Here
MODEL_ID = "./models/gemma-7b-it/"

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=[
        "GET",
        "PUT",
        "PATCH",
        "POST",
        "DELETE",
    ],
    allow_headers=["Origin", "X-Requested-With", "Content-Type", "Accept"],
)
llm_model = Model(model_id=MODEL_ID)
chat_room = llm_model.chat_room


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/get_information", response_model=InfomationData)
async def get_information():
    return InfomationData(llm_model, MODEL_ID.replace("./models/", "").replace("/", ""))


@app.get("/model_list")
async def model_list():
    return os.listdir("models")


@app.get("/get_chatroom_id")
async def get_chatroom_id():
    return chat_room.id


@app.post("/set_chatroom")
async def set_chatroom(data: PostSetChatRoomModel):
    print(
        f"[set_chatroom] Data: {data}",
    )
    chat_room.id = data.id
    chat_room.use_preprompt = data.use_preprompt
    chat_room.preprompt = data.preprompt
    chat_room.use_chat_history = data.use_chat_history
    chat_room.chat_history = data.chat_history


@app.delete("/delete_chatroom_knowledge")
async def delete_chatroom_knowledge(data: dict):
    return chat_room.delete_context_knowledge(data["filename"])


@app.delete("/reset_chatroom_knowledge")
async def reset_chatroom_knowledge():
    chat_room.delete_context_knowledge("")
    return len(chat_room.context_knowledge)


@app.post("/set_chatroom_knowledge")
async def set_chatroom_knowledge(data: list[UploadFile] = File(...)):
    print(
        f"[set_chatroom_knowledge] Data: {data}",
    )
    chat_room.delete_context_knowledge("")
    for item in data:
        await chat_room.add_context_knowledge(item)
    return len(chat_room.context_knowledge)


@app.post("/add_context_knowledge")
async def add_context_knowledge(data: UploadFile = File(...)):
    print(f"[add_context_knowledge] Data: {data}")
    await chat_room.add_context_knowledge(data)
    return len(chat_room.context_knowledge)


@app.post("/generate_text", response_model=ReturnGeneratedText)
async def generate_text(data: PostGenerateText):
    print(f"[generate_text] Data: {data}")
    output = await llm_model.generate_text(data)
    print(f"[generate_text] Generate Text: {output}")
    return output


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
