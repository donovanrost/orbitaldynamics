# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: strategy-branch registry relocation.

Status:
Published.

Selected slice:
Moved `strategy_branch.v1` from the facade registry into the existing
`Schema.CampaignRegistryContracts` module.

Why this slice:
The V3 campaign contract already names `strategy_branch.v1` as a nested contract.
Co-locating parent and child removes the remaining split in that registry family.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/campaign_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, strategy-branch validation, and generated schemas retain
the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Lint/strategy-branch, campaign repair/strategy, registry capability, and
  schema export tests passed: 12 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.CampaignRegistryContracts` passed
  with the expected schema-facade caller.
- Full touched-file formatting, whitespace, conflict-marker, and checked-in
  schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative relocation.

Last commit:
`c3e507bb` (`Move strategy branch registry contract`).

Next candidate:
Extract `study_benchmark.v1`, `manifest_field_reference.v1`, and
`result_artifact.v1` into a focused study/result registry module after confirming
their test boundary.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,649 to 18,621 lines.
- `CampaignRegistryContracts` increased from 147 to 175 lines and now owns the
  complete V1/V2/V3 campaign registry family.
- Published lint registry extraction: `17ac8ed2`.
