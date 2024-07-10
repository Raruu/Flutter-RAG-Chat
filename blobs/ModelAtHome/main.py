from fastapi import FastAPI
from llm_model import Model
from data_model import Data

# Put Your Model Here
MODEL_ID = "./gemma-7b-it"

app = FastAPI()
llm_model = Model(MODEL_ID)

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.post("/generate_text")
async def generate_text(data: Data):
    print(f"Data: {data}")
    output = llm_model.generate_text(data)
    print(f"Output: {output}")
    return output

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)