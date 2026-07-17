# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh command window/maneuver review replay callback removal.

Status:
Selected.

Selected slice:
Remove the repeated source-summary callback from the command-window and
maneuver-review replay paths across the facade, replay aggregator, and two
owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `command_window_replay_summary/1` and
`maneuver_review_replay_summary/1` functions, exact branch-family precedence,
provenance fallback, source and scope strings, command/maneuver pressure
fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/command_window.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/maneuver_review.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- four focused command/maneuver replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Candidate intent/counteroffer replay callback removal published as `c1dfa532`:
both paths are one-argument end to end, 30 focused tests passed, and bounded
review found no blocker.

Next candidate:
Remove the callback seam from one adjacent single-owner replay family after
this pair is published.

Blocked:
No.
