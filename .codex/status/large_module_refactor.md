# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh contact intent/provider counteroffer replay callback removal.

Status:
Review complete; ready to publish.

Selected slice:
Remove the repeated source-summary callback from the contact-intent and
provider-counteroffer replay paths across the facade, replay aggregator, and
two owners.

Why this slice:
The two owners have the same branch-family-first shape, receive the fixed
callback only through the replay aggregator, and already depend on
`SourceReportSummary`. They can own provenance fallback directly without
changing branch precedence or summary logic.

Public facade to preserve:
The public `contact_intent_replay_summary/1` and
`provider_counteroffer_replay_summary/1` functions, exact branch-family
precedence, provenance fallback, existing source and scope strings, capacity
and counteroffer fields, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/contact_intent.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/provider_counteroffer.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- six focused intent/counteroffer replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch selection and outputs
remain exact; no old callback arity remains; focused tests pass; and bounded
review finds no blocker.

Outcome:
The contact-intent and provider-counteroffer replay paths are now one-argument
end to end. Each owner calls `SourceReportSummary.build/1` directly for
provenance fallback while retaining branch-family precedence, existing source
strings, and its summary constructor. The four-file production diff removes
eight net lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- six focused replay files: 30 tests passed
- scoped `mix format --check-formatted`
- `git diff --check`
- old callback arity and invocation audits: no matches
- both owner compile-connected graphs: no dependency edge
- replay entry callers: aggregator only; provider helper retains `summary/3`
- bounded read-only review: clean, no findings

Last completed slice:
Candidate contention/resolution replay callback removal published as
`63e1f657`: both paths are one-argument end to end, 33 focused tests passed,
and bounded review found no blocker.

Next candidate:
Remove the callback seam from one adjacent single-owner replay family after
this pair is published.

Blocked:
No.
