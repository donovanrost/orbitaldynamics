# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: validation policy/catalog registry extraction.

Status:
Published.

Selected slice:
Moved `validation_tolerance_policy.v1`, `backend_acceptance_policy.v1`, and
`capability_catalog.v1` definitions into
`Schema.ValidationPolicyRegistryContracts`.

Why this slice:
The three definitions form the validation policy, backend acceptance, and public
capability catalog family with one explicit nested-contract relationship.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_policy_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, public capabilities, and the generated JSON Schema
bundle retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Validation policy, registry capability, and schema export tests passed:
  10 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.ValidationPolicyRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`70ac8436` (`Extract validation policy registry contracts`).

Next candidate:
Extract the contiguous `campaign_request_lint.v1` and `study_manifest_lint.v1`
registry definitions into `Schema.LintRegistryContracts`.

Blocked:
No.

Notes:
- `schema.ex` decreased from 18,736 to 18,691 lines.
- `ValidationPolicyRegistryContracts` is 54 lines.
- Local review confirmed the final diff contains no temporary map-tail code.
