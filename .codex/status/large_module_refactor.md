# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline declared candidate-rejection reason policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved declared reason collection, recursive splitting, token canonicalization,
alias mapping, and allowed fallback into the 99-line
`Timeline.CandidateRejectionReasonPolicy`. The 6,179-line `Timeline` retains two
private entry points for canonical and raw values; derived logic is unchanged.

Published commits:
Initially selected in `c71c6889`, corrected in `e59cf630`, and implemented in
`41dd8346`.

Verification:
- Strict warnings-as-errors compile passed across 3,782 files.
- Three focused declared/derived, nested capacity, and nested availability
  candidate rejection examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all nine moved clauses after normalizing
  only heads, facade names, and allowed-reason routing.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues; raw/canonical
  consumers remain distinct and derived logic is untouched.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline declared candidate-rejection reason policy extraction, initially
selected in `c71c6889`, corrected in `e59cf630`, and implemented in `41dd8346`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
