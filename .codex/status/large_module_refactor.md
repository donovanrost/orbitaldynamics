# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle/report JSON-property family expansion.

Status:
Completed and pushed.

Selected boundary:
Move the six contiguous candidate-rejection, timeline report/diff, lifecycle,
preservation, lifecycle-summary, and transition-application clauses from
`JsonSchemaPropertyRouter` into the existing `TimelineReportPropertyRouter`.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 772 lines across 76 contract-family clauses.
- Six adjacent clauses form a roughly 110-line timeline lifecycle/report
  boundary covering thirteen related contracts.
- They fit the existing timeline report/state owner and reuse its current lazy
  provider/context/fallback and timeline-context support.
- No recursive parent callback or cross-family property lookup is required.

Implementation:
Selected in `a9fa65d3` and implemented in `38ab9bad`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates the six selected clauses to
`TimelineReportPropertyRouter`. The family router now owns twelve related
timeline report/state routes. Its copied dispatch bodies preserve the original
lazy provider/context/fallback calls; the parent dropped its now-unused
`TimelineContextJsonSchema` alias.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed all six moved bodies are exact and all 76
  parent route heads remain exact and ordered.
- Xref reports twelve runtime edges from the parent to the timeline family.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,105 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 772 to 696 lines; the timeline family grew from
  122 to 236 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline lifecycle/report JSON-property family expansion, selected in
`a9fa65d3` and implemented in `38ab9bad`. The parent router moved from 772 to
696 lines.

Next candidate:
Re-rank the remaining mixed maneuver/strategy/activity tail against returning
to the still-large public `Schema` facade's provider-helper boundaries.

Blocked:
No.
