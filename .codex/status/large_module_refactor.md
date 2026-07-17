# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh validation replay source-summary callback removal.

Status:
Selected.

Selected slice:
Remove the repeated source-summary callback from freshness, refresh-budget, and
schema-validation replay paths across the facade, replay aggregator, validation
owner, and three leaf modules.

Why this slice:
All three replay families share `ReplaySummary.Validation`; every caller passes
the same `&source_report_summary/1`, and each leaf already depends on
`SourceReportSummary`. The complete callback seam can move to direct owner
calls without callbacks or compile cycles.

Public facade to preserve:
The three public `*_replay_summary/1` functions, exact branch-source
precedence, provenance fallback, pressure fields, assumptions, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/validation.ex`
- three `replay_summary/validation/*.ex` leaves
- `.codex/status/large_module_refactor.md`

Likely verification:
- six focused validation replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
All three replay paths are one-argument end to end; branch/source selection and
outputs remain exact; no old callback arity remains; focused tests pass; and
bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Candidate diff/rejection replay callback removal published as `37f533c3`:
both paths are one-argument end to end, 25 focused tests passed, and bounded
review found no blocker.

Next candidate:
Remove the callback seam from one adjacent replay owner after the validation
trio is published.

Blocked:
No.
