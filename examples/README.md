# Examples

Working integrations against the live Flare ParticipantRegister at `0xd523159981a545dA5C53Ddbba327A5E6438A171C`. Each subfolder is independent — clone the repo, `cd` into one, and run.

| Folder | What | Stack |
|---|---|---|
| [`read-with-viem/`](./read-with-viem) | Enumerate active participants, fetch each `infoURI`, print summary | Node ≥ 20 + viem v2 |
| [`read-with-ethers/`](./read-with-ethers) | Same, with ethers v6 | Node ≥ 20 + ethers v6 |
| [`register-with-cast/`](./register-with-cast) | Register directly from the command line; one `cast send` + a sample `participant.json` | Foundry (cast) + a funded wallet |

For the broader integration guide, see [`../docs/integrate.md`](../docs/integrate.md). For schema + hosting + CORS notes, see [`../docs/participant-json.md`](../docs/participant-json.md).
