# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh storage-downlink-pressure replay callback removal.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

Last completed slice:
Candidate objective/constraint replay callback removal published as `9ad25ac2`:
both paths are one-argument end to end, 20 focused tests passed, and bounded
review found no blocker.

Next candidate:
Remove the callback seam from one adjacent single-owner replay family after
this slice is published.

Blocked:
No.
