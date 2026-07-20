# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support source-row validation direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop optional branch-comparison source-row
wrapper.
Route its three callback-map entries directly to
`DecisionSupportValidation.validate_optional_branch_comparison_source_row/3`.
Keep callback-map composition, optional report validators that build
facade-owned contract callbacks, contract routing, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,165 lines.
- The wrapper only forwards the same three arguments and adds no guards,
  defaults, callbacks, path adaptation, or result transformation.
- Three callback entries across Cadence-import, Cadence-source-review, and
  operator-review maps can capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Removed the one-hop optional branch-comparison source-row wrapper and routed
all three callback-map entries directly to DecisionSupportValidation.
`schema.ex` moved from 6,165 to 6,157 lines.

Verification:
- Strict focused Cadence-import/Cadence-row/operator-review/campaign-repair
  baseline before routing: 8 passed.
- The same strict focused suite after routing: 8 passed.
- Strict adjacent JSON Schema export/candidate-refresh/fixture-visibility
  coverage: 17 passed.
- Strict full schema-export task: 1 passed.
- `mix xref callers OrbitalDynamics.Schema.DecisionSupportValidation` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static search confirms the wrapper definition and all indirect captures are
  gone from `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `d89c1114` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback arity/timing, issue ordering, paths/messages,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema decision-support source-row validation direct routing, selected in
`64de9fc0` and implemented in `d89c1114`.
`schema.ex` moved from 6,165 to 6,157 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
