# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: lint registry extraction.

Status:
Ready to publish.

Selected slice:
Moved `campaign_request_lint.v1` and `study_manifest_lint.v1` definitions into
`Schema.LintRegistryContracts`.

Why this slice:
The two definitions form the public lint-artifact family with pure registry data
and no runtime helper coupling.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/lint_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, executable lint validation, and the generated JSON
Schema bundle retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Lint/strategy-branch contracts, registry capability, schema export, campaign
  lint task, and manifest lint task tests passed: 24 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.LintRegistryContracts` passed with
  the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`8a2abc29` (`Update validation policy handoff`); current slice is not yet
committed.

Next candidate:
Move the remaining `strategy_branch.v1` registry definition into the existing
`Schema.CampaignRegistryContracts` family, then reassess study/result tooling.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,691 to 18,649 lines.
- `LintRegistryContracts` is 51 lines.
- Published validation policy registry extraction: `70ac8436`.
