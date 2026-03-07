
# # Simulated deepseek-coder output
# # # Simulated llama3.1 output
# # Please review the README.md of this repository and let me know what is missing.
# print('Hello World')
# print('Hello World')

from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello World"}
