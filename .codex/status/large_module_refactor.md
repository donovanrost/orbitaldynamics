# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: campaign registry contract extraction.

Status:
Published.

Selected slice:
Moved the V1 campaign plan, V2 repair, and V3 strategy registry definitions into
`Schema.CampaignRegistryContracts`.

Why this slice:
The definitions form one public artifact-generation family and are pure
declarative data. `Schema` remains the facade and merges the family into its
private registry.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/campaign_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- validation and lint entry points

Behavior/schema changes:
None. Registry contents and the complete generated JSON Schema bundle retain the
previously proven baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Campaign plan, campaign repair/strategy, registry capability, and schema
  export tests passed: 13 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.CampaignRegistryContracts` passed
  with the expected single compile-time caller.
- Compile-connected xref, focused formatting, whitespace, new-file no-index,
  conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`5ee30c47` (`Extract campaign registry contracts`).

Next candidate:
Extract the contiguous candidate-refresh registry family (`candidate_refresh`,
candidate activity/diff, freshness, invalidation, budget, refreshed window,
remaining horizon, and source lineage) into
`Schema.CandidateRefreshRegistryContracts`.

Blocked:
No.

Notes:
- `schema.ex` decreased from 19,377 to 19,223 lines.
- `CampaignRegistryContracts` is 147 lines.
- Published validation registry extraction: `bcb5adf7`.
