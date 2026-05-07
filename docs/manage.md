# Manage your listing

## Update your metadata

Edit the JSON file at your `infoURI`. Browsers re-fetch on next render. The portal's ISR cache refreshes within ~10 minutes.

No transaction needed unless you change the type or the URL itself.

## Change your participant type or URL

Re-call `register()` with the new values. The contract updates in place — same row, same `registeredAt`, bumped `updatedAt`.

```bash
cast send 0x09f15b14D16BA645661c576348E4d4C201242bF2 \
  "register(uint8,string)" <new_type> "<new_infoURI>" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

Or use the portal: visit `/new` while connected from your registered address and the form opens in edit mode.

## Deactivate

```bash
cast send 0x09f15b14D16BA645661c576348E4d4C201242bF2 \
  "unregister()" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

You disappear from `getActiveParticipants()` and `getParticipantsByType()`. Your row stays in the index — it's append-only.

## Reactivate

Call `register()` again with any params. Same `registeredAt`, bumped `updatedAt`, `active = true`.
