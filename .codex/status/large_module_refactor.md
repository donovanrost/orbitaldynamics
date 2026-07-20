# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review row-link validation direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop operator-review row-link wrapper.
Route its three callback-map entries directly to
`OperatorReviewValidation.validate_row_links/3`.
Keep callback-map composition, optional report validators that build
facade-owned contract callbacks, contract routing, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,157 lines.
- The wrapper only forwards the same three arguments and adds no guards,
  defaults, callbacks, path adaptation, or result transformation.
- Three callback entries across Cadence-import, Cadence-source-review, and
  operator-review maps can capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Removed the one-hop operator-review row-link wrapper and routed all three
callback-map entries directly to OperatorReviewValidation.
`schema.ex` moved from 6,157 to 6,154 lines.

Verification:
- Strict focused Cadence-import/Cadence-row/operator-review baseline before
  routing: 7 passed.
- The same strict focused suite after routing: 7 passed.
- Strict adjacent JSON Schema export/validation-evidence/fixture-visibility
  coverage: 19 passed.
- Strict full schema-export task: 1 passed.
- `mix xref callers OrbitalDynamics.Schema.OperatorReviewValidation` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static search confirms the wrapper definition and all indirect captures are
  gone from `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `0781f88b` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback arity/timing, issue ordering, paths/messages,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema operator-review row-link validation direct routing, selected in
`eb558891` and implemented in `0781f88b`.
`schema.ex` moved from 6,157 to 6,154 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
