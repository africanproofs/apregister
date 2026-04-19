# ParticipantRegister — docs

Integration-oriented docs for the on-chain participant registry. For the contract source + deployment + audit notes, see the [`apregister` README](../README.md) on GitLab.

Everything here is rendered two ways:

1. **Native GitLab rendering** — browse the repo, click a `.md`, you get markdown-rendered pages with the contract file tree right there.
2. **Web client** — `register.proofs.africa/docs` pulls the same files via the GitLab API and renders them with the portal's styling and navigation. The markdown files in this directory are the source of truth; the portal is a reader.

A single edit-and-push to `main` in this repo propagates to both views automatically (ISR cache on the portal refreshes within ~10 minutes).

## What's here

- [**Register directly**](./register-direct.md) — power-user path. One `cast send`, one JSON file you host yourself. No portal, no hand-holding. Covers contract addresses, participant types, `participant.json` schema + hosting, CORS gotchas, read/write recipes via `cast` and viem, gas costs, and why the contract is deliberately permissionless.

## Coming soon

- **Integration recipe for indexers** — event topics, pagination patterns for on-chain consumers.
- **Hosting quickstart** — zero-to-served `participant.json` on GitHub Pages / IPFS / Arweave in under 5 minutes.
- **Flare mainnet deployment notes** — contract address, gas posture, CREATE2 salt decisions.

## Contributing

Every file in this directory is picked up automatically by the portal (via a small manifest in the frontend — one line to add a new slug). Drop a new `.md`, open an MR, and once merged it's live at `register.proofs.africa/docs/<basename>` within the ISR window.

Conventions:

- One H1 per file — it becomes the page title.
- Relative links to source files (`../src/...`) auto-rewrite to GitLab blob URLs on the portal.
- Cross-doc links (`./other-doc.md`) rewrite to `/docs/other-doc` on the portal and stay as GitLab-native links on the repo.
- External URLs pass through unchanged.

## Related

- Contract interface: [`../src/IParticipantRegister.sol`](../src/IParticipantRegister.sol)
- Implementation: [`../src/ParticipantRegister.sol`](../src/ParticipantRegister.sol)
- JSON-LD template: [`../assets/participant.template.json`](../assets/participant.template.json)
- JSON schema: [`../assets/participant.schema.json`](../assets/participant.schema.json)
- Audit notes: repo `CLAUDE.md` § Audit Status
