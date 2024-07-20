from fastapi import FastAPI
from llm_model import Model
from request_data_model import RequestData
from information_model import InfomationData
import os

# Put Your Model Here
MODEL_ID = "./models/gemma-7b/"

app = FastAPI()
llm_model = Model(MODEL_ID)

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/information", response_model=InfomationData)
async def get_information():
    return InfomationData(llm_model.llm_model, MODEL_ID.replace('./models/', '').replace('/', ''))

@app.get("/model_list")
async def model_list():
    return os.listdir('models')

@app.post("/generate_text")
async def generate_text(data: RequestData):
    print(f"Data: {data}")
    output = llm_model.generate_text(data)
    print(f"Generate Text: {output}")
    return output

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)