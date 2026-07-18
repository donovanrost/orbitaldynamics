# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport plan-delta manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `manifest_row/2` and its exclusive `import_side/1` and `import_action/1`
clauses into internal `CadenceImport.PlanDeltaManifestRow.build/3`. Inject the
four shared review/adapter, activity-normalization, and compaction helpers.

Why this slice:
The reduced `CadenceImport` facade is 5,057 lines. This builder has one
`plan_delta_review` dispatch caller, an exact 33-key projection, cohesive
side/action rules used nowhere else, and a small shared dependency boundary.

Public facade to preserve:
All `CadenceImport` APIs; all plan-delta keys, interpolation, defaults, side and
action selection, status mapping, activity-context normalization, compaction,
deterministic ordering, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/plan_delta_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal builder owns the exact 33-key projection plus all exclusive
side/action clauses; the facade supplies four exact callbacks; focused tests,
strict compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Behavior/schema changes:
None intended.

Last completed slice:
Approval-requirement row builder published in `930077ec`; compact handoff
published in `9c424c85`.

Next candidate:
Remap the reduced `CadenceImport` module after this extraction.

Blocked:
No.
