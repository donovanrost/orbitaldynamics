# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Provider-counteroffer-summary callback collapse.

Status:
Selected; implementation pending.

Selected slice:
Make all three `ProviderCounterofferSummaryContracts` entry points direct through
shared owners, local aggregation helpers, and the direct report row validator;
remove the now-summary-only callback factory and orphan Schema helpers.

Why this slice:
After the report collapse, the 27-entry factory has exactly three callers, all
inside this 783-line summary owner. Every dependency is static/shared and the
row validator is now direct, so the factory and its Schema aggregation surface
can disappear as one cohesive boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, provider-counteroffer review,
import-readiness, and plan-impact summaries, exact paths/messages/order, derived
counts, consumers, deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/provider_counteroffer_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused provider-counteroffer and schema tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No provider-counteroffer callback factory or lookup/apply remains; shared/local
aggregation preserves exact behavior; focused, broader, and export checks pass;
and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Provider-counteroffer-report callback collapse published as `d56cf494`:
`schema.ex` fell from 11,300 to 11,297 lines and the report owner from 272 to
209. Report/row validation became direct while the summary factory stayed
complete. Two hundred four focused, 1,340 attributable broader, and 24 export
tests passed; compile, regeneration, xref, format, diff hygiene, and bounded
review were clean.

Blocked:
No.
