# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh link-capacity replay callback removal.

Status:
Review complete; ready to publish.

Selected slice:
Remove the source-summary callback from the link-capacity replay path across
the facade, replay aggregator, and owner.

Why this slice:
The owner receives the fixed callback only through the replay aggregator and
already depends on `SourceReportSummary` for branch-family lookup. It can own
the provenance fallback directly without changing branch precedence or summary
logic.

Public facade to preserve:
The public `link_capacity_replay_summary/1` function, exact branch-family
precedence, provenance fallback, source and scope values, throughput/provider
pressure fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/link_capacity.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- seven focused link-capacity replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
The replay path is one-argument end to end; branch selection and outputs remain
exact; no old callback arity remains; focused tests pass; and bounded review
finds no blocker.

Outcome:
The link-capacity replay path is now one-argument end to end. Its owner calls
`SourceReportSummary.build/1` directly for provenance fallback while retaining
branch-family precedence and the existing summary constructor. The three-file
production diff removes four net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- seven focused replay files: 24 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- owner compile-connected graph: no dependency edge
- owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate contact filter/allocation replay callback removal published as
`64de7f00`: both paths are one-argument end to end, 53 focused tests passed,
and bounded review found no blocker.

Next candidate:
Remove the callback seam from one adjacent single-owner replay family after
this slice is published.

Blocked:
No.
