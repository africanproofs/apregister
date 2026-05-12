# Your participant.json

The contract stores only your participant type and a URL. Everything else — name, logo, description, social links, infrastructure — lives in this JSON file at that URL.

## Minimum

```json
{
  "name": "Your Project",
  "url": "https://your-site.com"
}
```

That's the only hard requirement. Every field below is optional and additive.

## Full

```json
{
  "@context": {
    "@vocab": "https://schema.org/",
    "flare": "https://proofs.africa/ns/participant#"
  },
  "@type": "Organization",
  "name": "Kopano Oracle",
  "url": "https://kopano.africa",
  "description": "Southern-African FTSO provider.",
  "logo": "https://kopano.africa/brand/logo.svg",
  "flare:brand": {
    "icon": "https://kopano.africa/brand/icon.svg",
    "light": "https://kopano.africa/brand/logo-light.svg",
    "dark": "https://kopano.africa/brand/logo-dark.svg"
  },
  "flare:social": {
    "twitter": "https://twitter.com/kopanoOracle",
    "telegram": "https://t.me/kopano_oracle",
    "github": "https://github.com/kopano-oracle"
  },
  "flare:location": { "country": "ZA" },
  "flare:participant-type": 0,
  "flare:participant-type-label": "Provider",
  "flare:services": ["ftso", "fast-updates"],
  "flare:nodes": [{ "network": "flare", "role": "ftso-v2", "country": "ZA" }],
  "flare:tools": [
    { "category": "rpc", "name": "Kopano Flare RPC", "url": "https://flare-rpc.kopano.africa/ext/C/rpc", "networks": ["flare"] },
    { "category": "dashboard", "name": "Kopano FTSO Dashboard", "url": "https://dashboard.kopano.africa" }
  ]
}
```

JSON Schema: [`participant.schema.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.schema.json).

## Why `flare:participant-type`

The contract stores `(participantType, infoURI)` per address. Without `flare:participant-type` in the JSON, a consumer reading the file alone cannot tell which on-chain type slot it belongs to — they'd need a separate `getParticipant(address)` call to cross-reference.

Including the numeric type in the JSON:

- Lets static-site indexers categorise without an RPC call
- Lets schema validators catch JSONs that drift from their on-chain registration
- Provides a self-evident "this is a Wallet entry, not a Provider entry" signal for human readers

The numeric value MUST match what was used in `register()`. Edit your JSON to match if you migrate participant types via a re-register call.

`flare:participant-type-label` is the string mirror — same information, friendlier for human-readable UIs and JSON viewers.

## `flare:tools[]` — public ecosystem services

If your participant publishes public services to the Flare community — RPC endpoints, explorers, dashboards, faucets, bridges, indexers, etc. — declare them under `flare:tools[]`. This is distinct from `flare:nodes[]`, which declares operational hardware (the boxes you run nodes on, not URLs anyone can call).

Each entry has a `name`, a `url`, and a `category`:

```json
{
  "flare:tools": [
    {
      "category": "rpc",
      "name": "Kopano Flare RPC",
      "url": "https://flare-rpc.kopano.africa/ext/C/rpc",
      "networks": ["flare"]
    },
    {
      "category": "dashboard",
      "name": "Kopano FTSO Dashboard",
      "url": "https://dashboard.kopano.africa",
      "description": "Live submission/reveal accuracy + reward minimal-conditions status."
    }
  ]
}
```

Supported categories (12 total, schema enum):
`rpc`, `explorer`, `indexer`, `archive`, `dashboard`, `faucet`, `bridge`, `subgraph`, `analytics`, `dev-tool`, `educational`, `other`.

Per-entry fields:

| Field | Required | Notes |
|---|---|---|
| `name` | yes | ≤ 64 chars. Display name (e.g. "Kopano Flare RPC"). |
| `url` | yes | ≤ 256 chars. Must be `https://`. |
| `category` | yes | One of the 12 enum values above. |
| `networks` | no | Array of `"flare"` / `"songbird"` / `"coston2"` / `"coston"`. Omit when the tool is chain-agnostic (e.g. an educational site). |
| `description` | no | ≤ 200 chars. One-line tagline shown in directory hover cards. |

### Migrating from `flare:rpc[]`

The legacy `flare:rpc[]` array is **deprecated** but still validates. New JSONs should use `flare:tools[]` with `category: "rpc"`. Consumers should prefer `flare:tools[]` and fall back to `flare:rpc[]` only when absent.

Schema: see [`participant.schema.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.schema.json).

## Where to host

| Option | CORS | Notes |
|---|---|---|
| GitHub Pages | open | Best default |
| IPFS (with pinning) | open | Immutable per CID |
| Arweave | open | Permanent, pay-once |
| S3 / R2 / GCS | configure once | One-time bucket CORS rule |
| Self-hosted (your domain) | **must configure** | Default web servers miss CORS — see below |

## CORS — read this if you self-host

The browser fetches your JSON from the registry portal. The response must include `Access-Control-Allow-Origin: *` (or the portal's origin). Default nginx, Apache, and Caddy installations do NOT set this header.

Verify before you register:

```bash
curl -I -H "Origin: https://register.proofs.africa" https://yoursite.com/participant.json | grep -i access-control
```

No `access-control-allow-origin:` in the response means browsers will silently refuse the fetch and your profile will show "Profile metadata isn't available right now".

Fix:

| Server | Add this |
|---|---|
| nginx | `add_header Access-Control-Allow-Origin *;` in your server or location block |
| apache | `Header set Access-Control-Allow-Origin "*"` in `.htaccess` or vhost |
| caddy | `header Access-Control-Allow-Origin *` |
| Cloudflare in front | Disable orange-cloud proxy on the JSON path, or set the header via a Page Rule |

## Other constraints

- **HTTPS only** — `http://` URLs fail the browser's mixed-content policy
- **Valid JSON** — HTML error pages served with HTTP 200 break consumers
- **URL ≤ 256 bytes** — enforced by the contract

## Brand kit (optional)

Drop image files alongside your `participant.json` and the registry portal picks them up automatically — no extra JSON fields needed.

### Convention paths

| File | Used for |
|---|---|
| `brand/icon.svg` or `brand/icon.png` | Square icon / mark (directory cards, profile hero) |
| `brand/logo-light.svg` or `brand/logo-light.png` | Logo for light-background surfaces |
| `brand/logo-dark.svg` or `brand/logo-dark.png` | Logo for dark-background surfaces |

SVG is tried before PNG. If neither variant exists, the portal falls through to explicit JSON URLs, then TowoLabs (Providers only), then an initials tile.

### Supported hosts

Folder-level access is required for the convention to work:

| Supported | Not supported |
|---|---|
| Own website / server | Arweave (content-addressed, no folders) |
| GitHub Pages / GitHub raw | Single-file IPFS pins |
| GitLab Pages / GitLab raw | GitHub Gists |
| Amazon S3 / Cloudflare R2 / GCS | |
| IPFS directory pins | |
| Netlify | |

### Resolution chain

The portal resolves each image slot in this order:

**Icon slot** (directory cards + profile hero):
1. `{base}/brand/icon.svg` → `{base}/brand/icon.png`
2. `flare:brand.icon` in your JSON
3. Top-level `logo` in your JSON
4. TowoLabs image registry (Providers only)
5. Address initials tile

**Light / dark logo slots** (profile hero):
1. `{base}/brand/logo-light.svg` → `.png` (or dark equivalent)
2. `flare:brand.light` / `flare:brand.dark` in your JSON
3. Address initials tile

Explicit `flare:brand` URLs in your JSON remain supported for hand-editors and third-party indexers that don't follow the convention.

### CORS reminder

Brand files are fetched by the browser from the registry portal, so the same CORS rule applies: your host must send `Access-Control-Allow-Origin: *`. See § CORS above.
