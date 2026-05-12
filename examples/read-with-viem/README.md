# Read the registry with viem

Minimal example: connect to Flare mainnet, list all active participants from `ParticipantRegister`, fetch each participant's `infoURI` JSON, and print a summary.

## Run

```bash
npm install
node index.js
```

Requires Node ≥ 20.

## What it does

1. Defines the Flare mainnet chain (id 14, FLR, the public RPC).
2. Calls `getActiveParticipants()` on the live `ParticipantRegister` at `0xd523159981a545dA5C53Ddbba327A5E6438A171C` (verified on [Flarescan](https://flare-explorer.flare.network/address/0xd523159981a545dA5C53Ddbba327A5E6438A171C#code) + [Sourcify](https://sourcify.dev/#/lookup/0xd523159981a545dA5C53Ddbba327A5E6438A171C)).
3. For each active address: reads the participant tuple, fetches the `infoURI`, prints `(address, type, infoURI, name)`.

## Sample output (when participants exist)

```
Reading ParticipantRegister at 0xd5231599…A171C on Flare mainnet (chain 14)

Active participants: 1

  0x26534aC74153E3257dDD3471f96faA33D5D3B575
    type:     Provider (0)
    infoURI:  https://proofs.africa/participant.json
    name:     African Proofs
```

If the registry is empty, the script prints a one-line note.

## Adapt to your own contract

- Change `REGISTER` to your deployment address.
- Change the chain config (id + RPC) if you're on a different chain.
- Use `getParticipantsByType(uint8)` if you only want one type slot (e.g. all Providers).
