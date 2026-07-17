# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh storage-downlink-pressure replay callback removal.

Status:
Published as `028c3226`.

Selected slice:
Remove the source-summary callback from the storage-downlink-pressure replay
path across the facade, replay aggregator, and owner.

Why this slice:
The owner receives `&source_report_summary/1` only from the replay aggregator,
and the callback is the facade's one-line delegate to
`SourceReportSummary.build/1`. This small provenance-only path can own that
fixed dependency without changing its composed pressure summary.

Public facade to preserve:
The public `storage_downlink_pressure_replay_summary/1` function, exact
allocation/link/projection composition, source and scope values, pressure
fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/storage_downlink_pressure.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- two focused storage-downlink-pressure replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
The replay path is one-argument end to end; report composition and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The storage-downlink-pressure replay path is now one-argument end to end. Its
owner calls `SourceReportSummary.build/1` directly while retaining the existing
source-report composition and summary assembly. The three-file production diff
removes three net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- two focused replay files: 13 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- owner compile-connected graph: no dependency edge
- owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate storage-downlink-pressure replay callback removal published as
`028c3226`: the path is one-argument end to end, 13 focused tests passed, and
bounded review found no blocker.

Next candidate:
Audit the adjacent resource-filter/resource-projection callback seams as one
possible bounded pair.

Blocked:
No.
