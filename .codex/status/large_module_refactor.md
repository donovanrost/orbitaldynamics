# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh validation replay source-summary callback removal.

Status:
Published as `651df593`.

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
The freshness, refresh-budget, and schema-validation replay paths are now
one-argument end to end. Their leaves call `SourceReportSummary.build/1`
directly while retaining branch-source precedence and the existing
three-argument summary constructors. The production diff removes 39 net lines
across six files.

Verification gaps:
- `mix compile --warnings-as-errors`
- six focused replay files: 29 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- validation owner compile-connected graph: no dependency edge
- validation owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate validation replay callback removal published as `651df593`:
freshness, refresh-budget, and schema-validation are one-argument end to end,
29 focused tests passed, and bounded review found no blocker.

Next candidate:
Remove the callback seam from one adjacent objective/constraint replay owner,
subject to a fresh caller and test audit.

Blocked:
No.
