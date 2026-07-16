# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Quality-gate-row callback-bag collapse.

Status:
Completed and ready to publish.

Selected slice:
Replace the 14-entry callback bag in `QualityGateRowContracts` with direct
primitive, stable-ID, and readiness-context owners while retaining explicit
source-gate handoff, source-report handoff, and timeline validator boundaries.

Why this slice:
Live inventory leaves `schema.ex` at 11,762 lines. The 148-line row owner still
receives seven shared primitive/stable callbacks and four callbacks that merely
route to the extracted readiness-context owner. Only the two source handoff
checks and timeline validation remain genuine Schema orchestration hooks.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every quality-gate row/report
validation path, including stable row IDs, rank and capability enums, source
handoff checks, resource/operator/adapter/Cadence/timeline context, exact
messages/error order, aggregation consumers, replay consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/quality_gate_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No quality-gate-row callback bag or lookup/apply trampolines remain; direct
shared/context owners preserve validation and aggregation while only the two
source handoff and timeline validators remain injected; focused, broader, and
export checks pass; and bounded review finds no blocker.

Outcome:
Removed the 14-entry row callback bag and all owner trampolines. Primitive and
stable-ID validation now use direct shared owners; four readiness-context checks
call their extracted owner directly; source-gate, source-report, and timeline
validators remain explicit boundaries. The row aggregation helpers are
unchanged. One now-dead Schema wrapper was removed. `schema.ex` fell from 11,762
to 11,733 lines and the row owner from 148 to 96.

Verification:
- compile with warnings as errors passed
- 61 focused readiness/schema/replay/operator-review tests passed
- 1,054 broader candidate-refresh/operator-review tests passed
- 22 schema export tests passed
- compile-connected xref passed
- checked-in schema regeneration produced no diff
- format and diff hygiene passed
- bounded review found no findings

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Quality-gate-row callback-bag collapse; publication commit pending.

Blocked:
No.
