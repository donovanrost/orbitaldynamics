# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport proposed-contact manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `proposed_contact_manifest_row/2`, all three cadence-import-status clauses,
all three import-status clauses, and both activity-context clauses into internal
`CadenceImport.ProposedContactManifestRow.build/3`. Inject the three shared JSON
encoding, provider-field normalization, and compaction helpers.

Why this slice:
The reduced `CadenceImport` facade is 5,000 lines. The cluster has an exact
53-key projection, two facade callers, eight cohesive helper clauses used
nowhere else, and a small shared dependency boundary.

Public facade to preserve:
All `CadenceImport` APIs; all proposed-contact keys, ordering, defaults,
valid/missing/invalid import classification, nested trust-boundary fallback,
invalid-shape encoding, activity-context normalization, compaction,
deterministic output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/proposed_contact_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal builder owns the exact 53-key projection and all eight exclusive
status/context clauses; the facade supplies three exact callbacks; focused
tests, strict compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Behavior/schema changes:
None intended.

Last completed slice:
Plan-delta row builder published in `d3b9c980`; compact handoff published in
`73fd237c`.

Next candidate:
Remap the reduced `CadenceImport` module after this extraction.

Blocked:
No.
