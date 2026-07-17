# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh timeline diff/dependency-impact replay callback removal.

Status:
Review complete; ready to publish.

Selected slice:
Remove the repeated source-summary callback from the timeline-diff and
timeline-dependency-impact replay paths across the facade, replay aggregator,
and two owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `timeline_diff_replay_summary/1` and
`timeline_dependency_impact_replay_summary/1` functions, exact branch-family
precedence, provenance fallback, source and scope strings, diff/dependency
pressure fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/timeline_diff.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/timeline_dependency_impact.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- four focused diff/dependency replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The timeline-diff and timeline-dependency-impact replay paths are now
one-argument end to end. Each owner calls `SourceReportSummary.build/1`
directly for provenance fallback while retaining branch-family precedence and
its existing summary constructor. The four-file production diff removes eight
net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- four focused replay files: 21 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- both owner compile-connected graphs: no dependency edge
- both owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate integrity/lifecycle replay callback removal published as `0f9519cc`:
both paths are one-argument end to end, 24 focused tests passed, and bounded
review found no blocker.

Next candidate:
Remove the callback seam from one adjacent timeline replay family after this
pair is published.

Blocked:
No.
