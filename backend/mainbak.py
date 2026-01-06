
from typing import Union
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from services.ChatbotDeepseek import chat, chat_stream, reset_conversation, get_last_assistant_reply

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"Hello": "World"}


@app.post("/chat")
async def chat_endpoint(payload: dict):
    """非流式对话接口，返回完整回答。

    请求体示例：{"prompt": "..."
    """
    prompt = payload.get("prompt", "")
    # 根据需要可按会话 ID / 用户 ID 控制 reset_conversation()
    # 这里先简单地复用全局对话历史
    answer = chat(prompt)
    return {"prompt": prompt, "answer": answer}


@app.post("/chat/stream")
async def chat_stream_endpoint(payload: dict):
    """流式对话接口（POST），使用 SSE 向前端推送内容。

    请求体示例：{"prompt": "..."}
    前端可以使用 fetch/XHR 建立连接并逐步读取响应流，
    或者在支持的环境下使用 EventSource polyfill。
    """
    prompt = payload.get("prompt", "")

    def event_generator():
        # 将 ChatbotDeepseek.chat_stream 产生的内容转换为 SSE 格式
        import json
        for piece in chat_stream(prompt):
            yield f"data: {json.dumps(piece)}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")
