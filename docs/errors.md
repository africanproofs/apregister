# Errors

When a contract call reverts, the revert data carries one of these custom errors. Use this table to diagnose.

| Error | When | Fix |
|---|---|---|
| `EmptyInfoURI()` | You called `register()` with an empty string for `infoURI` | Pass a non-empty URL |
| `UriTooLong()` | Your `infoURI` is longer than 256 bytes | Shorten the URL — use IPFS CID or short hosting |
| `NotRegistered()` | You called `unregister()` from an address that has never registered | Register first, or check you're using the right wallet |
| `NotActive()` | You called `unregister()` on a record that's already deactivated | Already inactive — no action needed |
| `OffsetOutOfBounds()` | You called `getParticipants(offset, limit)` with `offset` past the index length | Use `participantCount()` to bound your offset |
