import os
from enum import Enum
from datetime import datetime, timezone
from uuid import uuid4
from typing import Any


from uagents import Agent, Context, Model, Protocol
from uagents.experimental.quota import QuotaProtocol, RateLimit
from uagents_core.models import ErrorMessage

# Import chat protocol components
from uagents_core.contrib.protocols.chat import (
    chat_protocol_spec,
    ChatMessage,
    ChatAcknowledgement,
    TextContent,
    EndSessionContent,
    StartSessionContent,
)

from langchain_agent import run_langchain_agent

agent = Agent()

#Startup Handler - Print agent details
@agent.on_event("startup")
async def startup_handler(ctx: Context):
    # Print agent details
    ctx.logger.info(f"My name is {ctx.agent.name} and my address is {ctx.agent.address}")

# Create the chat protocol
chat_proto = Protocol(spec=chat_protocol_spec)

def create_text_chat(text: str, end_session: bool = True) -> ChatMessage:
    content = [TextContent(type="text", text=text)]
    if end_session:
        content.append(EndSessionContent(type="end-session"))
    return ChatMessage(
        timestamp=datetime.now(timezone.utc),
        msg_id=uuid4(),
        content=content,
    )

# Chat protocol message handler
@chat_proto.on_message(ChatMessage)
async def handle_message(ctx: Context, sender: str, msg: ChatMessage):
    ctx.logger.info(f"Got a message from {sender}: {msg.content}")
    ctx.storage.set(str(ctx.session), sender)
    
    # Send acknowledgement
    await ctx.send(
        sender,
        ChatAcknowledgement(
            acknowledged_msg_id=msg.msg_id, 
            timestamp=datetime.now(timezone.utc)
        ),
    )

    # Process message content
    for content in msg.content:
        if isinstance(content, StartSessionContent):
            ctx.logger.info(f"Got a start session message from {sender}")
            continue
        elif isinstance(content, TextContent):
            ctx.logger.info(f"Got a message from {sender}: {content.text}")
            ctx.storage.set(str(ctx.session), sender)
            
            # Send to langchain agent for response
            # 🔥 Call LangChain agent instead of external AI agent
            try:
                response_text = await run_langchain_agent(content.text)
            except Exception as err:
                ctx.logger.error(f"LangChain agent error: {err}")
                response_text = "Sorry, I had trouble processing your request."

            # Send response back as chat message
            await ctx.send(sender, create_text_chat(response_text))
        else:
            ctx.logger.info(f"Got unexpected content from {sender}")    


# Acknowledgement Handler - Process received acknowledgements
@chat_proto.on_message(ChatAcknowledgement)
async def handle_acknowledgement(ctx: Context, sender: str, msg: ChatAcknowledgement):
    ctx.logger.info(f"Received acknowledgement from {sender} for message: {msg.acknowledged_msg_id}")


# Include the protocol in the agent to enable the chat functionality
# This allows the agent to send/receive messages and handle acknowledgements using the chat protocol
agent.include(chat_proto, publish_manifest=True)

if __name__ == '__main__':
    agent.run()