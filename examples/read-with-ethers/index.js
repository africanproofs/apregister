// Read the live ParticipantRegister on Flare mainnet using ethers v6.
// Run: npm install && node index.js

import { JsonRpcProvider, Contract } from "ethers";

const RPC = "https://flare-api.flare.network/ext/C/rpc";
const REGISTER = "0xd523159981a545dA5C53Ddbba327A5E6438A171C";

const abi = [
  "function getActiveParticipants() view returns (address[])",
  "function getParticipant(address) view returns (tuple(address owner, uint8 participantType, string infoURI, bool active, uint256 index, uint256 registeredAt, uint256 updatedAt))",
];

const TYPE_LABELS = ["Provider", "DeFi", "Wallet", "Tool", "FAssetsAgent", "Exchange", "App", "AgenticAI"];

async function main() {
  const provider = new JsonRpcProvider(RPC, 14);
  const registry = new Contract(REGISTER, abi, provider);

  console.log(`Reading ParticipantRegister at ${REGISTER} on Flare mainnet (chain 14)\n`);

  const active = await registry.getActiveParticipants();

  console.log(`Active participants: ${active.length}`);
  if (active.length === 0) {
    console.log("(Registry is currently empty. See CHANGELOG.md 2026-05-12 for the redeploy context.)");
    return;
  }

  for (const addr of active) {
    const p = await registry.getParticipant(addr);

    let name = "(metadata unreachable)";
    try {
      const res = await fetch(p.infoURI, { headers: { Accept: "application/json" } });
      if (res.ok) {
        const meta = await res.json();
        name = meta.name ?? name;
      }
    } catch {
      // Participant-controlled URL; ignore fetch errors.
    }

    console.log(`\n  ${addr}`);
    console.log(`    type:     ${TYPE_LABELS[Number(p.participantType)]} (${p.participantType})`);
    console.log(`    infoURI:  ${p.infoURI}`);
    console.log(`    name:     ${name}`);
  }
}

main().catch((err) => {
  console.error("Error:", err.message ?? err);
  process.exit(1);
});
