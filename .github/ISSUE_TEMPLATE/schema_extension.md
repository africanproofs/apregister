---
name: Schema extension
about: Propose a new field, category, or convention for assets/participant.schema.json
title: ''
labels: schema
assignees: ''
---

## Motivation

<!-- What participant type or use case needs this? What can't they express today? -->

## Proposed shape

<!-- Show the new field(s) as they would appear in a participant.json. Include example values. -->

```json
{
  "flare:your-field": "example"
}
```

## Compatibility

<!-- Field additions are backward-compatible (JSON-LD consumers ignore unknown fields). Renames are NOT permitted. Confirm which you're proposing. -->

- [ ] Addition (backward-compatible)
- [ ] Deprecation of an existing field (specify which; keep validating for legacy JSONs)
- [ ] Rename (NOT permitted — see CONTRIBUTING.md § Schema extensions)

## Affects

<!-- Which surfaces need updating after schema change? -->

- [ ] `assets/participant.schema.json` (the schema itself)
- [ ] `types/participant.d.ts` (regenerated via `scripts/check-drift.sh`)
- [ ] `docs/participant-json.md` (the reader-facing doc)
- [ ] `README.md` Optional Fields table
- [ ] Reference portal (closed-source; flag if your proposal needs portal support)

## Workflow

This follows the 5-step process in [`CONTRIBUTING.md` § Schema extensions](../../CONTRIBUTING.md#schema-extensions):

1. Open this issue with the `schema` label.
2. After agreement, PR the schema change.
3. Regenerate `types/` + `abi/` via `bash scripts/check-drift.sh`.
4. Commit the regenerated files alongside the schema change.
5. CI gate `drift` verifies committed `types/` + `abi/` match what would be regenerated.

## References

<!-- Links to similar fields in other registries, schema.org / JSON-LD precedents, etc. -->
