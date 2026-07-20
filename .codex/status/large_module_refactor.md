# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline report/state JSON-property family extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the six contiguous timeline feedback, integrity, dependency-impact,
publication, activity-state, and activity-precondition clauses from
`JsonSchemaPropertyRouter` into a timeline report/state family owner. Keep the
parent router's exact clause heads/order as delegations and reuse shared
property support without adding a recursive callback.

Selection evidence:
- The parent router remains 1,226 lines across 76 contract-family clauses.
- Six adjacent clauses form a 114-line timeline report/state boundary across
  focused timeline dispatchers.
- The cohort shares only lazy providers, stable-ID context, fallback, and the
  existing timeline-context schema owner.
- No clause recursively re-enters the parent property router, so the split is a
  direct mechanical family move.

Implementation:
- Added a 122-line `TimelineReportPropertyRouter` with the six mechanically
  moved timeline report/state clause bodies.
- Kept all six original parent clause heads in place as ordered delegations.
- Reused shared lazy provider/context/fallback support and the existing
  `TimelineContextJsonSchema` owner without a parent callback.
- The parent router moved from 1,226 to 1,147 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all six moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the six intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,099 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline report/state JSON-property family extraction, selected in `64b5888d`
and implemented in `fd18ecf4`. The parent router moved from 1,226 to 1,147
lines.

Next candidate:
Re-rank the adjacent result-artifact/contact-planning families against a
cohesive facade provider-family extraction.

Blocked:
No.
