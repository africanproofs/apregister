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
  "flare:services": ["ftso", "fast-updates"],
  "flare:nodes": [{ "network": "flare", "role": "ftso-v2", "country": "ZA" }],
  "flare:rpc": [{ "network": "flare", "url": "https://flare-rpc.kopano.africa/ext/C/rpc" }]
}
```

JSON Schema: [`participant.schema.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.schema.json).

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
