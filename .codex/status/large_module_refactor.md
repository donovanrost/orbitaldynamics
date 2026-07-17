# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh timeline publication/transition replay callback removal.

Status:
Published as `e10128e3`.

Selected slice:
Remove the repeated source-summary callback from the timeline-publication and
timeline-transition-application replay paths across the facade, replay
aggregator, and two owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `timeline_publication_replay_summary/1` and
`timeline_transition_application_replay_summary/1` functions, exact
branch-family precedence, provenance fallback, source and scope strings,
publication/transition fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/timeline_publication.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/timeline_transition_application.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- five focused publication/transition replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The timeline-publication and timeline-transition-application replay paths are
now one-argument end to end. Each owner calls `SourceReportSummary.build/1`
directly for provenance fallback while retaining branch-family precedence and
its existing summary constructor. The four-file production diff removes eight
net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- five focused replay files: 20 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- both owner compile-connected graphs: no dependency edge
- both owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate publication/transition replay callback removal published as
`e10128e3`: both paths are one-argument end to end, 20 focused tests passed,
and bounded review found no blocker.

Next candidate:
Audit the adjacent operational-readiness/quality-gate callback seams as one
bounded pair.

Blocked:
No.
