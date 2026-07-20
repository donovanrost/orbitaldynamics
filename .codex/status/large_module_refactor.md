# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection source-row validation direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop optional candidate-rejection source-row
wrapper.
Route its two callback-map entries directly to
`CandidateRejectionValidation.validate_optional_source_row/3`.
Keep callback-map composition, report validators that add registry/model-limit
context, contract routing, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,154 lines.
- The wrapper only forwards the same three arguments and adds no guards,
  defaults, callbacks, path adaptation, or result transformation.
- Two callback entries across Cadence-import and Cadence-source-review maps can
  capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Removed the one-hop optional candidate-rejection source-row wrapper and routed
both callback-map entries directly to CandidateRejectionValidation.
`schema.ex` moved from 6,154 to 6,151 lines.

Verification:
- Strict focused Cadence-import/Cadence-row/candidate-refresh baseline before
  routing: 6 passed.
- The same strict focused suite after routing: 6 passed.
- Strict adjacent JSON Schema export/candidate-refresh/fixture-visibility
  coverage: 26 passed.
- Strict full schema-export task: 1 passed.
- `mix xref callers
  OrbitalDynamics.Schema.CandidateRejectionValidation` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static search confirms the wrapper definition and both indirect captures are
  gone from `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `ec799ada` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback arity/timing, issue ordering, paths/messages,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema candidate-rejection source-row validation direct routing, selected in
`07f4e3d0` and implemented in `ec799ada`.
`schema.ex` moved from 6,154 to 6,151 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
