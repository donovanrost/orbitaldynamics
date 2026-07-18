# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-vocabulary policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move status/approval lifecycle category classification, supported-value checks,
and repairable-status classification into `Timeline.LifecycleVocabularyPolicy`.
`Timeline` retains private entry points for status category, approval category,
unsupported status/approval checks, and repairable status. All vocabulary lists
cross the boundary explicitly.

Why this slice:
The reduced Timeline facade is 6,791 lines. These 18 clauses own the shared
lifecycle vocabulary consumed by reports, transition assembly, direct helpers,
and review policy callbacks. The boundary consolidates classification without
moving any artifact assembly.

Planned proof:
- Focused Timeline transition/state examples covering executed, terminal,
  blocked, repairable, planned, protected, review-required, rejected,
  unsupported, and nil values.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 18 moved clauses after normalizing only the
  five facade names and constant arguments.
- Format, diff, whitespace, ownership, exactly-five-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-transition review policy extraction, selected in `f1b8de8b`,
implemented in `b16a898a`, and handed off in `2c0d16f2`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing lifecycle
transition assembly and remaining activity normalization.

Blocked:
No.
