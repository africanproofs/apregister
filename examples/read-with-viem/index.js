// Read the live ParticipantRegister on Flare mainnet using viem.
// Run: npm install && node index.js

import { createPublicClient, http, defineChain } from "viem";

const flare = defineChain({
  id: 14,
  name: "Flare",
  nativeCurrency: { name: "Flare", symbol: "FLR", decimals: 18 },
  rpcUrls: { default: { http: ["https://flare-api.flare.network/ext/C/rpc"] } },
});

const REGISTER = "0xd523159981a545dA5C53Ddbba327A5E6438A171C";

const abi = [
  {
    type: "function",
    name: "getActiveParticipants",
    inputs: [],
    outputs: [{ type: "address[]" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getParticipant",
    inputs: [{ type: "address", name: "who" }],
    outputs: [{
      type: "tuple",
      components: [
        { name: "owner", type: "address" },
        { name: "participantType", type: "uint8" },
        { name: "infoURI", type: "string" },
        { name: "active", type: "bool" },
        { name: "index", type: "uint256" },
        { name: "registeredAt", type: "uint256" },
        { name: "updatedAt", type: "uint256" },
      ],
    }],
    stateMutability: "view",
  },
];

const TYPE_LABELS = ["Provider", "DeFi", "Wallet", "Tool", "FAssetsAgent", "Exchange", "App", "AgenticAI"];

async function main() {
  const client = createPublicClient({ chain: flare, transport: http() });

  console.log(`Reading ParticipantRegister at ${REGISTER} on Flare mainnet (chain ${flare.id})\n`);

  const active = await client.readContract({
    address: REGISTER,
    abi,
    functionName: "getActiveParticipants",
  });

  console.log(`Active participants: ${active.length}`);
  if (active.length === 0) {
    console.log("(Registry is currently empty. See CHANGELOG.md 2026-05-12 for the redeploy context.)");
    return;
  }

  for (const addr of active) {
    const p = await client.readContract({
      address: REGISTER,
      abi,
      functionName: "getParticipant",
      args: [addr],
    });

    let name = "(metadata unreachable)";
    try {
      const res = await fetch(p.infoURI, { headers: { Accept: "application/json" } });
      if (res.ok) {
        const meta = await res.json();
        name = meta.name ?? name;
      }
    } catch {
      // Network error / CORS / 404 — leave the placeholder. infoURI hosting
      // is the participant's responsibility; the contract doesn't validate it.
    }

    console.log(`\n  ${addr}`);
    console.log(`    type:     ${TYPE_LABELS[p.participantType]} (${p.participantType})`);
    console.log(`    infoURI:  ${p.infoURI}`);
    console.log(`    name:     ${name}`);
  }
}

main().catch((err) => {
  console.error("Error:", err.message ?? err);
  process.exit(1);
});
