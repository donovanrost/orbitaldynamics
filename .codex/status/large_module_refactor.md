# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh readiness/quality-gate replay callback removal.

Status:
Published as `337007e2`.

Selected slice:
Remove the repeated source-summary callback from the operational-readiness and
quality-gate replay paths across the facade, replay aggregator, and two owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `operational_readiness_replay_summary/1` and
`quality_gate_replay_summary/1` functions, exact branch-family precedence,
provenance fallback, source and scope strings, publication context, pressure,
import eligibility, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/operational_readiness.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/quality_gate.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- 15 focused readiness/quality replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The operational-readiness and quality-gate replay paths are now one-argument
end to end. Each owner calls `SourceReportSummary.build/1` directly for
provenance fallback while retaining branch-family precedence, publication
context, pressure helpers, and its existing summary constructor. The four-file
production diff removes eight net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- 15 focused replay files: 49 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- both owner compile-connected graphs: no dependency edge
- both owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate readiness/quality replay callback removal published as `337007e2`:
both paths are one-argument end to end, 49 focused tests passed, and bounded
review found no blocker.

Next candidate:
Audit the adjacent model-acceptance/validation-safety-case callback seams as
one bounded pair.

Blocked:
No.
