from fastapi import FastAPI
from llm_model import Model
from data_models.request_data_model import RequestData
from data_models.information_model import InfomationData
import os
from data_models.chat_room import ChatRoom

# Put Your Model Here
MODEL_ID = "./models/gemma-7b-it/"

app = FastAPI()
llm_model = Model(model_id=MODEL_ID)
chat_room = llm_model.chat_room


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/information", response_model=InfomationData)
async def get_information():
    return InfomationData(
        llm_model.llm_model, MODEL_ID.replace("./models/", "").replace("/", "")
    )


@app.get("/model_list")
async def model_list():
    return os.listdir("models")


@app.get("/get_chatroom_id")
async def get_chatroom_id():
    return chat_room.id


@app.post("/set_chatroom")
async def set_chatroom(data: dict):
    print(
        f"[set_chatroom] Data: {data}",
    )
    chat_room.id = data["id"]
    chat_room.use_preprompt = data["use_preprompt"]
    chat_room.preprompt = data["preprompt"]
    chat_room.use_chat_history = data["use_chat_history"]
    chat_room.chat_history = data["chat_history"]


@app.post("/generate_text")
async def generate_text(data: RequestData):
    print(f"[generate_text] Data: {data}")
    output = await llm_model.generate_text(data)
    print(f"[generate_text] Generate Text: {output}")
    return output


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
