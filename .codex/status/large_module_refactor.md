# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh timeline feedback/operational timeline replay callback removal.

Status:
Selected.

Selected slice:
Remove the repeated source-summary callback from the timeline-feedback and
operational-timeline replay paths across the facade, replay aggregator, and two
owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `timeline_feedback_replay_summary/1` and
`operational_timeline_replay_summary/1` functions, exact branch-family
precedence, provenance fallback, source and scope strings, feedback/timeline
pressure fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/timeline_feedback.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/operational_timeline.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- three focused feedback/timeline replay files
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
Candidate command-window/maneuver-review replay callback removal published as
`0ececfa0`: both paths are one-argument end to end, 20 focused tests passed,
and bounded review found no blocker.

Next candidate:
Remove the callback seam from one adjacent timeline replay family after this
pair is published.

Blocked:
No.
