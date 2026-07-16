# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-projection report-count message restoration.

Status:
Complete and published.

Selected slice:
Restore the five generic equality messages lost when
`ResourceProjectionReportCountContracts` moved from Schema's `/5` equality
facade to the primitive `/5` function.

Why this slice:
The flow-row verification exposed three failures in the full resource-
projection file. Git history identifies `7e015529` as the regression: Schema's
`/5` facade emitted `must equal <expected>`, while the primitive `/5` default
emits a nil message. Two additional unasserted call sites share the defect.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, resource-projection report count
paths, expected values, exact `must equal <expected>` messages and issue order,
report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema/resource_projection_report_count_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- full resource-projection and focused schema/report tests
- broader candidate-refresh/operator-review regression if shared code changes
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
All five former `/5` equality calls use the primitive `/6` form with the exact
legacy generic message; the full resource-projection file and export checks
pass; and bounded review finds no blocker.

Outcome:
A local `/5` equality wrapper now delegates to PrimitiveValidation `/6` with
the exact legacy `must equal <expected>` message, while 13 custom `/6` calls
remain unchanged. The formerly red resource-projection file is 49/49; the full
focused aggregate is 214/214 and 22 export tests pass. Compile, xref, checked-in
regeneration, format, diff hygiene, and bounded review were clean.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Resource-projection report-count message restoration; publication commit
pending.

Blocked:
No.
