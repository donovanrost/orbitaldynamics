# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review row callback-provider extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move callback-key ordering and external contract wiring from
`operator_review_row_domain_callbacks/0` into an internal
`Schema.OperatorReviewRowCallbacks.build/1`, injecting only facade-private
validators. Leave the separate four-entry package registry unchanged.

Why this slice:
`Schema` is 7,409 lines. The row-domain registry is a 163-line responsibility
with 86 ordered callback keys, 58 stable external captures, and 28
facade-private captures.

Current coupling/problem:
The facade owns the complete operator-review row dependency registry, callback
ordering, and dozens of external domain/handoff module captures.

Public facade to preserve:
All `Schema` APIs; operator-review row/package and Cadence-import validation
behavior; callback keys, order, values, arities, error ordering, deterministic
output, and all schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operator_review_row_callbacks.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The new provider owns the exact ordered 86-key registry and 58 external
captures; `Schema` passes only 28 private callback captures; focused
operator-review, Cadence-import, review-handoff, timeline, and export tests
pass; strict compile, full byte-clean schema regeneration, exact registry
comparison, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, export proof, and
  independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Base Cadence-import callback provider published as implementation `1554fcd4`
and handoff `8001a9ed`: focused 34/34, strict 3,670-file compile, full
byte-clean schema regeneration, exact 35-key comparison, and independent
review passed.

Next candidate:
Remap the reduced `Schema` facade and choose between the small operator-review
package registry and remaining campaign/contact callback registries.

Blocked:
No.
