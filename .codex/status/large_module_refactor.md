# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport quality-gate manifest-row builder extraction.

Status:
Implementation published as `01fc9f40`; handoff publication pending.

Selected slice:
Move `quality_gate_manifest_row/2` into internal
`CadenceImport.QualityGateManifestRow.build/3`. Inject the five shared facade
helpers for review action, adapter status, readiness cadence-import context,
readiness resource context, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,419 lines. The builder had 33 projected keys, two ordered
context merges, five shared dependencies, and one facade caller. The facade is
now 5,388 lines.

Public facade to preserve:
All `CadenceImport` APIs; all quality-gate keys and value expressions; cadence
then resource context precedence, action/status, import/approval defaults,
compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/quality_gate_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 33-key projection and ordered merges; the
facade supplies five exact callbacks; focused tests, strict compile,
equivalence/API checks, and independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,698 files.
- Exact AST proof: 33/33 entries, full normalized body, ordered merges, and all
  public facade definitions match selection `d82271bc`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Resource-over-cadence-over-base precedence, action/status,
import/approval defaults, compaction, deterministic output, and APIs are exact.

Last completed slice:
Quality-gate row builder selected in `d82271bc` and published in `01fc9f40`:
focused 100/100, strict 3,698-file compile, exact 33-entry/full-body and
merge-order comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
