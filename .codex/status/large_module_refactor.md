# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh timeline activity-state replay callback removal.

Status:
Review complete; ready to publish.

Selected slice:
Remove the remaining source-summary callbacks from the five timeline
activity-state replay paths across the facade, replay aggregator, dedicated
owners, and shared single-state selection owner.

Why this slice:
These are the final facade callback transports. State, lifecycle, and
precondition already depend on `SourceReportSummary`; status and approval share
one selection owner that can call `SourceReportSummary.build/1` directly while
retaining its separate source-field selection API.

Public facade to preserve:
The five public `timeline_activity_*_replay_summary/1` functions, exact direct
state and branch-family precedence, contract matching, provenance fallback,
source and scope strings, pressure fields, assumptions, and deterministic
ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- five timeline activity-state replay owner/selection files
- `.codex/status/large_module_refactor.md`

Likely verification:
- seven focused timeline activity-state replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
All five replay paths are one-argument end to end; direct/branch/provenance
selection and outputs remain exact; no facade callback transport remains;
focused tests pass; and bounded review finds no blocker.

Outcome:
All five timeline activity-state replay paths are now one-argument end to end.
Dedicated owners and the shared single-state selection owner call
`SourceReportSummary.build/1` directly for provenance fallback while retaining
direct-state and branch-family precedence, contract matching, source-field
selection, and existing summary constructors. The seven-file production diff
removes 24 net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- seven focused replay files: 36 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- global facade callback and invocation audits: no matches
- owner compile-connected graphs: no dependency edge
- replay owner callers: aggregator only
- shared selection callers: replay owner and retained source-field helper
- bounded read-only review: clean, no findings

Last completed slice:
Candidate acceptance/safety replay callback removal published as `d3324fa7`:
both paths are one-argument end to end, 25 focused tests passed, and bounded
review found no blocker.

Next candidate:
After callback removal is complete, re-inventory the live large-module
hotspots and choose the next responsibility extraction.

Blocked:
No.
