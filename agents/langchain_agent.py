import os
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langchain.agents import initialize_agent, AgentType
from web3 import Web3
from eth_account import Account


@tool
def send_layerzero_message(message: str) -> str:
    """Send a cross-chain message using LayerZero contract. Example: 'deploy'"""
    rpc_url = os.getenv("RPC_URL")
    private_key = os.getenv("PRIVATE_KEY")
    contract_address = os.getenv("CONTRACT_ADDRESS")

    if not (rpc_url and private_key and contract_address):
        return "Missing RPC_URL, PRIVATE_KEY or CONTRACT_ADDRESS in environment."

    w3 = Web3(Web3.HTTPProvider(rpc_url))
    acct = w3.eth.account.from_key(private_key)

    CONTRACT_ABI = [
        {
            "inputs": [
                {"internalType": "uint32", "name": "_dstEid", "type": "uint32"},
                {"internalType": "string", "name": "_message", "type": "string"},
                {"internalType": "bool", "name": "_payInLzToken", "type": "bool"},
            ],
            "name": "quote",
            "outputs": [
                {
                    "components": [
                        {"internalType": "uint256", "name": "nativeFee", "type": "uint256"},
                        {"internalType": "uint256", "name": "lzTokenFee", "type": "uint256"},
                    ],
                    "internalType": "struct MessagingFee",
                    "name": "fee",
                    "type": "tuple",
                }
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint32", "name": "_dstEid", "type": "uint32"},
                {"internalType": "string", "name": "_message", "type": "string"},
            ],
            "name": "send",
            "outputs": [],
            "stateMutability": "payable",
            "type": "function",
        },
    ]

    # ✅ Fix: use keyword args
    contract = w3.eth.contract(address=contract_address, abi=CONTRACT_ABI)

    dst_eid = 40285
    pay_in_lz_token = False

    # Quote fee
    fee = contract.functions.quote(dst_eid, message, pay_in_lz_token).call()
    native_fee = fee[0]

    # Build & sign tx
    tx = contract.functions.send(dst_eid, message).build_transaction({
        "from": acct.address,
        "value": native_fee,
        "gas": 500000,
        "nonce": w3.eth.get_transaction_count(acct.address),
    })
    signed = acct.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)

    return f"Sent tx: {tx_hash.hex()} (fee: {w3.from_wei(native_fee, 'ether')} ETH)"


# Init LLM + agent once (with OpenRouter)
llm = ChatOpenAI(
    model="openai/gpt-4o-mini",  # OpenRouter model name
    temperature=0,
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)

agent = initialize_agent([send_layerzero_message], llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION, verbose=False)


async def run_langchain_agent(query: str) -> str:
    """Call LangChain agent with user query and return response."""
    return await agent.arun(query)   # use async run
import os
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langchain.agents import initialize_agent, AgentType
from web3 import Web3
from eth_account import Account


@tool
def send_layerzero_message(message: str) -> str:
    """Send a cross-chain message using LayerZero contract. Example: 'deploy'"""
    rpc_url = os.getenv("RPC_URL")
    private_key = os.getenv("PRIVATE_KEY")
    contract_address = os.getenv("CONTRACT_ADDRESS")

    if not (rpc_url and private_key and contract_address):
        return "Missing RPC_URL, PRIVATE_KEY or CONTRACT_ADDRESS in environment."

    w3 = Web3(Web3.HTTPProvider(rpc_url))
    acct = w3.eth.account.from_key(private_key)

    CONTRACT_ABI = [
        {
            "inputs": [
                {"internalType": "uint32", "name": "_dstEid", "type": "uint32"},
                {"internalType": "string", "name": "_message", "type": "string"},
                {"internalType": "bool", "name": "_payInLzToken", "type": "bool"},
            ],
            "name": "quote",
            "outputs": [
                {
                    "components": [
                        {"internalType": "uint256", "name": "nativeFee", "type": "uint256"},
                        {"internalType": "uint256", "name": "lzTokenFee", "type": "uint256"},
                    ],
                    "internalType": "struct MessagingFee",
                    "name": "fee",
                    "type": "tuple",
                }
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint32", "name": "_dstEid", "type": "uint32"},
                {"internalType": "string", "name": "_message", "type": "string"},
            ],
            "name": "send",
            "outputs": [],
            "stateMutability": "payable",
            "type": "function",
        },
    ]

    # ✅ Fix: use keyword args
    contract = w3.eth.contract(address=contract_address, abi=CONTRACT_ABI)

    dst_eid = 40285
    pay_in_lz_token = False

    # Quote fee
    fee = contract.functions.quote(dst_eid, message, pay_in_lz_token).call()
    native_fee = fee[0]

    # Build & sign tx
    tx = contract.functions.send(dst_eid, message).build_transaction({
        "from": acct.address,
        "value": native_fee,
        "gas": 500000,
        "nonce": w3.eth.get_transaction_count(acct.address),
    })
    signed = acct.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed.rawTransaction)

    return f"Sent tx: {tx_hash.hex()} (fee: {w3.from_wei(native_fee, 'ether')} ETH)"


# Init LLM + agent once (with OpenRouter)
llm = ChatOpenAI(
    model="openai/gpt-4o-mini",  # OpenRouter model name
    temperature=0,
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)

agent = initialize_agent([send_layerzero_message], llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION, verbose=False)


async def run_langchain_agent(query: str) -> str:
    """Call LangChain agent with user query and return response."""
    return await agent.arun(query)   # use async run
