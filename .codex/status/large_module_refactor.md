# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Branch-comparison-report callback-bag and field-metadata ownership collapse.

Status:
Implemented, verified, reviewed, and ready to publish.

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
The 27-entry callback bag and every lookup/apply trampoline are gone. The owner
now calls shared primitive, CampaignPlanner model-limit, and BranchEvent
contracts directly; it also owns the row-count and pressure-handoff field lists,
with Schema JSON generation consuming the same row-count source. Five orphaned
Schema imports disappeared. `schema.ex` fell from 10,280 to 10,179 lines and the
owner from 547 to 474, for a net reduction of 174 lines.

Verification gaps:
- Full repository suite not run. The broader regression remains at the
  baseline-proven 1,340/1,345 result with the same five unrelated
  campaign-planner failures.

Last completed slice:
Branch-comparison-report callback and metadata ownership collapse, publication
pending: 194 focused and 24 export tests passed; the broader suite produced the
baseline-proven 1,340/1,345 result. Compile, checked-in export regeneration,
compile-connected xref, format, diff hygiene, and bounded review were clean.

Blocked:
No.
