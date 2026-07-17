# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh timeline activity-state replay callback removal.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

Last completed slice:
Candidate acceptance/safety replay callback removal published as `d3324fa7`:
both paths are one-argument end to end, 25 focused tests passed, and bounded
review found no blocker.

Next candidate:
After callback removal is complete, re-inventory the live large-module
hotspots and choose the next responsibility extraction.

Blocked:
No.
