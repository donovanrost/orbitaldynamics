# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh resource filter/projection replay callback removal.

Status:
Selected.

Selected slice:
Remove the repeated source-summary callback from the resource-filter and
resource-projection replay paths across the facade, replay aggregator, and two
owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the same fixed
callback only from the replay aggregator, and already depend on
`SourceReportSummary`. They can own the provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `resource_filter_replay_summary/1` and
`resource_projection_replay_summary/1` functions, exact branch-family
precedence, provenance fallback, source and scope values, pressure fields,
assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/resource_filter.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/resource_projection.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- eight focused resource filter/projection replay files
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
Candidate storage-downlink-pressure replay callback removal published as
`028c3226`: the path is one-argument end to end, 13 focused tests passed, and
bounded review found no blocker.

Next candidate:
Remove the callback seam from one adjacent single-owner replay family after
this pair is published.

Blocked:
No.
