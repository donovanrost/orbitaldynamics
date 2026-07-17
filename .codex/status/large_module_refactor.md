# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate diff/rejection replay source-summary callback removal.

Status:
Published as `37f533c3`.

Selected slice:
Remove the repeated source-summary callback from the candidate diff and
candidate rejection replay pair across the facade, replay aggregator, candidate
owner, and leaf modules.

Why this slice:
Both replay families share `ReplaySummary.Candidate`; every caller passes the
same `&source_report_summary/1`, and both leaf modules already depend on the
new `SourceReportSummary.build/1` owner. The complete callback seam can be
removed without a compile cycle or policy choice.

Public facade to preserve:
`CandidateRefresh.candidate_diff_replay_summary/1`,
`candidate_rejection_replay_summary/1`, exact summary maps, branch-source
precedence, provenance fallback, assumptions, and deterministic ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/candidate.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/candidate/diff.ex`
- `lib/orbital_dynamics/candidate_refresh/replay_summary/candidate/rejection.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- four focused candidate diff/rejection replay files
- callback/caller and compile-connected audits
- compile, format, diff hygiene, and bounded review

Definition of done:
Both replay paths are one-argument end to end; branch/source selection and
outputs remain exact; no old callback arity remains; focused tests pass; and
bounded review finds no blocker.

Outcome:
Removed the source-summary callback from both replay paths across all three
internal layers. CandidateRefresh and the replay/candidate owners now use
one-argument delegates, while the leaves call `SourceReportSummary.build/1`
directly. The five-file scope is net -16 lines.

Verification gaps:
- Strict compilation, formatting, and diff hygiene pass.
- Four focused candidate diff/rejection replay files pass 25/25.
- No old callback arity or invocation remains in the five-file family.
- Compile-connected xref adds no candidate-owner compile edge; xref callers
  show only the replay aggregator at runtime.
- Branch-source precedence, provenance fallback, and output construction were
  audited against selection commit `b9a3ae79`.
- Independent bounded review found no blocker.

Last completed slice:
Candidate diff/rejection replay callback removal published as `37f533c3`:
both paths are one-argument end to end, 25 focused tests passed, and bounded
review found no blocker.

Next candidate:
Remove the same callback seam from one adjacent replay family after this pair
is published.

Blocked:
No.
