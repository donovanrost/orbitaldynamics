# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-readiness manifest-row builder extraction.

Status:
Implementation published as `452ab316`; handoff publication pending.

Selected slice:
Move `operational_readiness_manifest_row/2` into internal
`CadenceImport.OperationalReadinessManifestRow.build/3`. Inject eight shared
facade helpers for generic action, review action, adapter status, four readiness
contexts, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,348 lines. The builder had 36 projected keys, four ordered
context merges, eight shared dependencies, and one facade caller. The facade is
now 5,317 lines.

Public facade to preserve:
All `CadenceImport` APIs; all operational-readiness keys and value expressions;
resource, adapter, training, then cadence context precedence; generic action,
import/approval defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/operational_readiness_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 36-key projection and four ordered merges;
the facade supplies eight exact callbacks; focused tests, strict compile,
equivalence/API checks, and independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,700 files.
- Exact AST proof: 36/36 entries, generic action, full normalized body, four
  ordered merges, and all public facade definitions match `5bacc482`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Cadence-over-training-over-adapter-over-resource-over-base precedence,
generic action, import/approval defaults, compaction, deterministic output, and
APIs are exact.

Last completed slice:
Operational-readiness row builder selected in `5bacc482` and published in
`452ab316`: focused 100/100, strict 3,700-file compile, exact 36-entry/full-body
and four-merge comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
