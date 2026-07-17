# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Branch-comparison-report callback-bag and field-metadata ownership collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 27-entry branch-comparison keyword bag with direct shared validation,
CampaignPlanner model-limit, and BranchEvent contract owners; move the row-count
and pressure-handoff field lists into the branch-comparison owner so executable
validation and JSON-schema generation share one cohesive source.

Why this slice:
Live inventory leaves `schema.ex` at 10,280 lines. The 547-line
branch-comparison owner routes 27 dependencies through lookup/apply even though
all primitives and contract helpers have direct owners; its two Schema-owned
field lists are cohesive branch-comparison metadata rather than facade state.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all branch-comparison-report
fields, exact paths/messages/order, consumers, deterministic artifacts, and
schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/branch_comparison_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused branch-comparison/campaign-strategy/operator-review tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No branch-comparison keyword bag or lookup/apply trampolines remain; validation
dependencies and field metadata have cohesive direct owners, exact messages and
ordering remain stable, focused/broader/export checks pass, and bounded review
finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-allocation aggregate-summary callback collapse published as `ef117696`:
`schema.ex` fell from 10,441 to 10,280 lines and the owner from 1,330 to 1,236;
the 33-entry domain factory became two explicit validator hooks and 20 facade
orphans disappeared. Two hundred seventy-four focused, 1,340 attributable
broader, and 24 export tests passed; compile, regeneration, xref, format, diff
hygiene, and bounded review were clean.

Blocked:
No.
