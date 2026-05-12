# Read the registry with ethers v6

Minimal example: same as [`../read-with-viem`](../read-with-viem) but using ethers v6 instead of viem. Pick whichever matches your existing stack.

## Run

```bash
npm install
node index.js
```

Requires Node ≥ 20.

## What it does

Identical to the viem example: enumerates active participants on Flare mainnet, fetches each `infoURI`, prints a summary. The only differences are the imports (`JsonRpcProvider`, `Contract` from `ethers`) and the ABI declaration style (ethers uses string-array ABIs by convention).

See [`../read-with-viem/README.md`](../read-with-viem/README.md) for the full setup notes and sample output.
