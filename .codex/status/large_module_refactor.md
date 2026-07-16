# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: candidate-refresh registry contract extraction.

Status:
Published.

Selected slice:
Moved the candidate-refresh artifact registry family and its seven family-owned
field lists into `Schema.CandidateRefreshRegistryContracts`.

Why this slice:
The ten definitions cover one refresh lifecycle family. The module now owns its
registry maps and shared schema metadata; facade validators read the three
publication-lineage lists through narrow accessors rather than an option bag.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`
- validation and lint entry points

Behavior/schema changes:
None. Registry contents and the complete generated JSON Schema bundle retain the
baseline fingerprint, and executable lineage validators consume the same lists.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Candidate-refresh contracts, resource provenance, registry capability, and
  schema export tests passed: 20 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref callers OrbitalDynamics.Schema.CandidateRefreshRegistryContracts`
  passed with the expected schema-facade caller.
- Compile-connected xref, full touched-file formatting, whitespace, new-file
  no-index, conflict-marker, and checked-in-schema cleanliness checks passed.

Verification gaps:
- The full suite was not run for this family extraction.

Last commit:
`104b0b34` (`Extract candidate refresh registry contracts`).

Next candidate:
Extract the adjacent accepted planning-state family (`accepted_planning_state`,
`spacecraft_state_estimate`, and `maneuver_execution_delta`) into a focused
registry module after confirming its exact span and tests.

Blocked:
No.

Notes:
- `schema.ex` decreased from 19,223 to 18,883 lines.
- `CandidateRefreshRegistryContracts` is 372 lines.
- Published registry modules: validation (`bcb5adf7`) and campaign (`5ee30c47`).
