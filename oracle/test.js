const express = require("express");
const { ethers } = require("ethers");
require("dotenv").config();

const app = express();
const PORT = 3000;

// ----------- Avalanche (Fuji) setup -----------
const avalancheProvider = new ethers.JsonRpcProvider(
  "https://api.avax-test.network/ext/bc/C/rpc"
);

const aTokenAddress = "0xb1c85310a1b809C70fA6806d27Da425C1261F801";
const aTokenAbi = [
  "function POOL() view returns (address)",
  "function UNDERLYING_ASSET_ADDRESS() view returns (address)",
];

const poolAbi = [
  "function getReserveNormalizedIncome(address asset) view returns (uint256)",
];

// ----------- Hedera EVM setup -----------
const hederaRpcUrl = "https://testnet.hashio.io/api";
const privateKey = process.env.PRIVATE_KEY;      // Your Hedera operator key
const contractAddress = "0x06d96Fa408Bcd6a4C75C2ffFa3B6cd33666F5926"; // getReserveNormalizedIncome contract

const hederaProvider = new ethers.JsonRpcProvider(hederaRpcUrl);
const wallet = new ethers.Wallet(privateKey, hederaProvider);

const hederaAbi = [
  "function updateReserveNI(uint256 _reserveNI) external",
  "function getReserveNI() view returns (uint256)",
];
const hederaContract = new ethers.Contract(contractAddress, hederaAbi, wallet);

// ----------- Global cache -----------
let normalizedIncome = null;


async function getReserveNI() {
  const reserveNI = await hederaContract.getReserveNI();

  console.log("Current Reserve NI in Hedera contract:", reserveNI.toString());
}

getReserveNI();

