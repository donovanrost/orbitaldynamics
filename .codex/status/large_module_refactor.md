# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CandidateRefresh source-report summary assembly ownership.

Status:
Ready to publish.

Selected slice:
Move source-report normalization, provenance collection, and final assembly
behind `SourceReportSummary.build/1`; keep
`CandidateRefresh.source_report_summary/1` as the public delegate.

Why this slice:
Nearly every replay facade passes the same `&source_report_summary/1` callback.
Giving the existing source-summary module full assembly ownership removes the
parent-only implementation and creates a direct owner that later replay-family
slices can call without a parent-module compile cycle.

Public facade to preserve:
`OrbitalDynamics.CandidateRefresh.source_report_summary/1`, exact summary maps,
provenance paths/counts, fallback behavior for non-maps, and deterministic
ordering.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/candidate_refresh/source_report_summary.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused source-report summary and provenance families
- compile-connected dependency check
- compile, format, diff hygiene, and bounded review

Definition of done:
The public facade delegates both map and fallback inputs to one summary owner;
summary output remains exact; focused tests pass; dependency shape is narrow;
and bounded review finds no blocker.

Outcome:
Added `SourceReportSummary.build/1` as the owner for input normalization,
provenance collection, assembly, and non-map fallback. The public facade is now
a one-line delegate. `candidate_refresh.ex` fell from 641 to 626 lines and the
owner grew from 304 to 317; the bounded scope is net -2 lines.

Verification gaps:
- Strict compilation, formatting, and diff hygiene pass.
- Five focused source-summary/provenance files pass 9/9, including exact
  non-map fallback equivalence through the public facade.
- The moved body and fallback were audited against selection commit
  `bfc88f46`; call/evaluation order is unchanged.
- Compile-connected xref adds no facade compile edge; module callers confirm
  the facade uses the owner at runtime.
- Independent review's fallback-proof finding was corrected; re-review found
  no blocker.

Last completed slice:
Schema capability and validation-evidence direct-owner routing published as
`9cef6d55`: eight redundant wrappers are gone, 32 focused tests passed, export
bytes remained exact, and bounded review found no blocker.

Next candidate:
Remove the repeated source-summary callback from one cohesive replay family
once `SourceReportSummary.build/1` is the direct owner.

Blocked:
No.
