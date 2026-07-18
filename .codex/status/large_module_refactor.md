# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport suppression manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `suppression_manifest_row/3` into internal
`CadenceImport.SuppressionManifestRow.build/4`. Preserve the shared approval,
rule-match, escalation, provider-result, status, and compaction helpers in the
facade and inject nine exact callbacks.

Why this slice:
The reduced facade is 4,790 lines. The shared contact/resource suppression
builder has two dispatch callers and an exact 113-key projection with a clear
responsibility boundary.

Public facade to preserve:
All `CadenceImport` APIs; both suppression variants; all 113 keys, interpolation,
fallback order, provider-result normalization, policy selection, compaction,
determinism, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/suppression_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal builder owns the exact 113-key projection; shared helpers stay in
the facade behind nine exact callbacks; focused tests, strict compile,
equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Behavior/schema changes:
None intended.

Last completed slice:
Contact-intent row builder published in `eec84abb`; handoff in `8811ec77`.

Next candidate:
Remap the reduced facade after this extraction.

Blocked:
No.
