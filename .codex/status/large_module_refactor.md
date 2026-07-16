# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation registry contract extraction.

Status:
Ready to publish.

Selected slice:
Moved the six validation registry definitions for reference fixtures, reference
reports, checks, validation reports, batch reports, and migration reports into
`Schema.ValidationRegistryContracts`.

Why this slice:
The definitions form one declarative family inside the large inline registry and
have no runtime validator coupling. `Schema` remains the public facade and merges
the extracted maps into its private registry.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- validation and lint entry points

Behavior/schema changes:
None. Registry contents and the complete generated JSON Schema bundle match
baseline commit `bf49d9ea` exactly.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Validation evidence, policy, scoring, registry capability, and schema export
  tests passed: 18 tests.
- A SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` matched
  baseline `bf49d9ea` exactly:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.ValidationRegistryContracts` passed
  with the expected single compile-time caller.
- Compile-connected xref, focused formatting, whitespace, new-file no-index,
  conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`bf49d9ea` (`Update refactor handoff`); current slice is not yet committed.

Next candidate:
Extract the contiguous V1/V2/V3 campaign plan, repair, and strategy registry
definitions into `Schema.CampaignRegistryContracts` using the same private merge
boundary and exact bundle-equivalence proof.

Blocked:
No.

Notes:
- `schema.ex` decreased from 19,474 to 19,377 lines.
- `ValidationRegistryContracts` is 124 lines.
- Local review caught and removed whole-registry formatter churn before publish.
- `evaluate_branch/2` remains deferred because its current input surface is too
  broad for a clean direct extraction.
