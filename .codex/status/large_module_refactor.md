# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh contact contention/resolution replay callback removal.

Status:
Published as `63e1f657`.

Selected slice:
Remove the repeated source-summary callback from the contact-contention and
contact-contention-resolution replay paths across the facade, replay
aggregator, and two owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `contact_contention_replay_summary/1` and
`contact_contention_resolution_replay_summary/1` functions, exact branch-family
precedence, provenance fallback, source and scope values, contention/resolution
pressure and handoff fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/contact_contention.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/contact_contention_resolution.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- seven focused contention/resolution replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The contact-contention and contact-contention-resolution replay paths are now
one-argument end to end. Each owner calls `SourceReportSummary.build/1`
directly for provenance fallback while retaining branch-family precedence and
its existing summary constructor. The four-file production diff removes eight
net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- seven focused replay files: 33 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- both owner compile-connected graphs: no dependency edge
- both owner callers: replay aggregator only
- bounded read-only review: clean, no findings

Last completed slice:
Candidate contention/resolution replay callback removal published as
`63e1f657`: both paths are one-argument end to end, 33 focused tests passed,
and bounded review found no blocker.

Next candidate:
Audit the adjacent contact-intent/provider-counteroffer callback seams as one
possible bounded pair.

Blocked:
No.
