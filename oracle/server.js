const express = require("express");
const { ethers } = require("ethers");

const app = express();
const PORT = 3000;

// Avalanche Fuji RPC
const provider = new ethers.providers.JsonRpcProvider(
  "https://api.avax-test.network/ext/bc/C/rpc"
);

// aAvaUSDC (aToken) on Fuji
const aTokenAddress = "0xb1c85310a1b809C70fA6806d27Da425C1261F801";

// Minimal ABIs
const aTokenAbi = [
  "function POOL() view returns (address)",
  "function UNDERLYING_ASSET_ADDRESS() view returns (address)",
];

const poolAbi = [
  "function getReserveNormalizedIncome(address asset) view returns (uint256)",
];

// Global cache
let normalizedIncome = null;

async function fetchNormalizedIncome() {
  try {
    const aToken = new ethers.Contract(aTokenAddress, aTokenAbi, provider);

    const [poolAddr, underlying] = await Promise.all([
      aToken.POOL(),
      aToken.UNDERLYING_ASSET_ADDRESS(),
    ]);

    const pool = new ethers.Contract(poolAddr, poolAbi, provider);
    const income = await pool.getReserveNormalizedIncome(underlying);

    normalizedIncome = income.toString();
    console.log("Updated Normalized Income:", normalizedIncome);
  } catch (err) {
    console.error("Error fetching normalized income:", err.message);
  }
}

// fetch once per second
setInterval(fetchNormalizedIncome, 4000);

// Express endpoint
app.get("/normalized-income", (req, res) => {
  if (!normalizedIncome) {
    return res.status(503).json({ error: "Data not ready yet" });
  }
  res.json({ normalizedIncome });
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
  fetchNormalizedIncome(); // initial call
});
