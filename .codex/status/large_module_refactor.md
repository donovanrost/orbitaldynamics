# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh objective/constraint replay source-summary callback removal.

Status:
Published as `9ad25ac2`.

Selected slice:
Remove the repeated source-summary callback from the objective-gap and
constraint replay paths across the facade, replay aggregator, and two owners.

Why this slice:
Both adjacent owners receive the same `&source_report_summary/1` only from the
replay aggregator, and the callback is the public facade's one-line delegate to
`SourceReportSummary.build/1`. The two small, provenance-only paths can move
that fixed dependency to their owners without changing their summary logic.

Public facade to preserve:
The public `objective_gap_replay_summary/1` and `constraint_replay_summary/1`
functions, exact report selection, source and scope strings, pressure fields,
assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/objective_gap.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/constraint.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- objective-gap and constraint focused replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; report selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The objective-gap and constraint replay paths are now one-argument end to end.
Each owner calls `SourceReportSummary.build/1` directly, while its report
selection and summary assembly remain unchanged. The four-file production diff
is line-neutral and removes both callback seams.

Verification gaps:
- `mix compile --warnings-as-errors`
- two focused replay files: 20 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- both owner compile-connected graphs: no dependency edge
- both owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate objective/constraint replay callback removal published as `9ad25ac2`:
both paths are one-argument end to end, 20 focused tests passed, and bounded
review found no blocker.

Next candidate:
Remove the callback seam from the adjacent storage-downlink-pressure replay
owner, subject to a fresh caller and test audit.

Blocked:
No.
