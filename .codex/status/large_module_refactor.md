# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport policy-escalation manifest-row builder extraction.

Status:
Implementation published as `b83cc43f`; handoff publication pending.

Selected slice:
Move `policy_escalation_manifest_row/2` into internal
`CadenceImport.PolicyEscalationManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,568 lines. The builder was a 38-line transformation with
30 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,540 lines.

Public facade to preserve:
All `CadenceImport` APIs; all policy-escalation keys and value expressions;
constant present-status semantics, approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/policy_escalation_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 30-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,693 files.
- Exact AST proof: 30/30 entries, full normalized body, and all public facade
  definitions match selection `ef84fb57`.
- Both constant `"present"` status uses are exact.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Policy-escalation action/status, approval defaults, compaction,
deterministic output, and APIs are exact.

Last completed slice:
Policy-escalation row builder selected in `ef84fb57` and published in
`b83cc43f`: focused 100/100, strict 3,693-file compile, exact 30-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
