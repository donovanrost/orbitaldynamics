# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection condition policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved locked-overlap, negative-margin, short-contact, policy-blocked,
stale-state, model-incompatible, and quality-gate-failed classification plus
their token normalization into the 105-line
`Timeline.CandidateRejectionConditionPolicy`. The 6,064-line Timeline retains
seven thin classifier facades so the derived-reason coordinator remains
unchanged, plus one normalization facade for the existing activity-precondition
callback.

Published commits:
Initially selected in `a5fbcc2d`, corrected in `70396748` after strict compile
identified the activity-precondition normalization callback, and implemented in
`6e5fc6f3`.

Verification:
- Strict warnings-as-errors compile passed across 3,785 files after preserving
  the normalization callback facade.
- Three focused candidate-rejection examples passed before and after extraction.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all nine moved clauses after normalizing
  only public/private definition kind.
- Format, diff, whitespace, exactly-eight-facade, unchanged Timeline
  public-definition, sole-production-consumer, callback-wiring, and xref checks
  passed.
- Independent read-only review found no production-code issues and confirmed
  exact fields, tokens, thresholds, comparison strictness, normalization,
  transitive dependency adapters, coordinator order, and callback preservation.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline candidate-rejection condition policy extraction, initially selected in
`a5fbcc2d`, corrected in `70396748`, and implemented in `6e5fc6f3`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
