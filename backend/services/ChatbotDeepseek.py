# deepseek key: sk-ace5394199ac40498fd5dd238d1b87ef
# 编写一个聊天工具，仅有 chat(prompt) 接口，历史数据用全局变量保存
# 调用 deepseek 的服务，key 使用上面的 key
# 使用 openai 的接口风格调用 deepseek 的服务
# 无需任何文件读取保存动作，直接调用接口，返回模型的回答内容

from openai import OpenAI

openai = OpenAI(api_key="sk-ace5394199ac40498fd5dd238d1b87ef",
                base_url="https://api.deepseek.com")

chat_history = []


def reset_conversation():
    """Reset the global chat history to start a new conversation."""
    global chat_history
    chat_history = []


def get_chat_history() -> list[dict]:
    """Return a shallow copy of the current conversation history.

    方便外部模块（如 FastAPI 路由、日志模块）查看当前会话上下文，
    避免直接修改全局列表。
    """
    return list(chat_history)


def get_last_assistant_reply() -> str | None:
    """Return the last assistant message content in the current history.

    对于使用 chat_stream 的场景，上层在消费完整个流之后，可以再调用
    这个函数拿到本轮的完整回复，用于存库、日志、后续处理等。
    """
    for msg in reversed(chat_history):
        if msg.get("role") == "assistant":
            return msg.get("content")
    return None


def chat(prompt: str, *, model: str = "qwen3-max", api_key: str | None = None, base_url: str | None = None, system: str | None = None) -> str:
    """Send a prompt to the Deepseek chat model and return the assistant's reply.

    This is a non-streaming helper that waits for the full answer and then
    returns it as a single string.
    """
    global chat_history

    # Append user message to history
    chat_history.append({"role": "user", "content": prompt})

    # Call the Deepseek chat completion API (non-streaming)
    response = openai.chat.completions.create(
        model="deepseek-chat",
        messages=chat_history,
    )

    # Extract assistant's reply
    assistant_reply = response.choices[0].message.content

    # Append assistant message to history
    chat_history.append({"role": "assistant", "content": assistant_reply})

    return assistant_reply


def chat_stream(prompt: str, *, model: str = "deepseek-chat", api_key: str | None = None, base_url: str | None = None, system: str | None = None):
    """Stream a chat response from the Deepseek model for backend callers.

    设计目标：
    - 供 FastAPI 等上层模块直接调用，用于向前端推送流式内容；
    - 本函数本身不负责打印，只负责：维护对话历史 + 逐块产出内容；
    - 流结束后，会自动把完整回复写入全局 chat_history，外部如需
      完整结果，可调用 get_last_assistant_reply()。

    常见用法（FastAPI 示例）：

        def event_gen():
            for piece in chat_stream(prompt):
                yield f"data: {piece}\n\n"  # SSE

        return StreamingResponse(event_gen(), media_type="text/event-stream")
    """
    global chat_history, openai

    # 可选 system 提示词：插入到历史最前面（若你频繁设置，需要外部自行控制去重）
    if system is not None:
        chat_history.insert(0, {"role": "system", "content": system})

    # 用户消息入历史
    chat_history.append({"role": "user", "content": prompt})

    # 准备客户端（允许临时覆盖 api_key/base_url）
    client = openai
    if api_key is not None or base_url is not None:
        client = OpenAI(
            api_key=api_key if api_key is not None else "sk-ace5394199ac40498fd5dd238d1b87ef",
            base_url=base_url if base_url is not None else "https://api.deepseek.com",
        )

    # 调用流式接口
    stream = client.chat.completions.create(
        model=model,
        messages=chat_history,
        stream=True,
    )

    full_reply_parts: list[str] = []

    for chunk in stream:
        delta = chunk.choices[0].delta
        if not delta or delta.content is None:
            continue

        content_piece = delta.content
        full_reply_parts.append(content_piece)

        # 将当前增量内容交给调用方（用于向前端转发）
        yield content_piece

    # 流结束后，把完整回复拼接并记录到历史中
    assistant_reply = "".join(full_reply_parts)
    if assistant_reply:
        chat_history.append({"role": "assistant", "content": assistant_reply})


if __name__ == "__main__":
    """Simple manual test for streaming interface.

    直接运行本文件：
        python services/ChatbotDeepseek.py

    可以在控制台观察流式增量输出是否正常。
    """
    reset_conversation()

    test_prompt = "请用中文简要介绍一下你自己，并分段输出几句话。"
    print("[Streaming test] prompt:", test_prompt)
    print("[Streaming test] reply:", end=" ", flush=True)

    for piece in chat_stream(test_prompt):
        # 模拟服务端向客户端不断推送增量内容
        print(piece, end="", flush=True)

    print("\n\n[Streaming test finished]\n")

