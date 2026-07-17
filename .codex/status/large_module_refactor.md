# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh top-level callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 27-entry `CandidateRefreshContracts` keyword bag with direct shared
and extracted owners, retaining only named explicit validators for boundaries
that still require Schema-owned context.

Why this slice:
Live inventory leaves `schema.ex` at 11,185 lines. This compact 155-line owner
and its sole caller route primitives, collection traversal, and already
extracted candidate-refresh validators through 27 lookup/apply entries; only a
small set of nested report validators still crosses Schema-owned boundaries.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all candidate-refresh fields,
nested reports/rows, exact paths/messages/order, consumers, deterministic
artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused candidate-refresh and schema tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No candidate-refresh keyword bag or lookup/apply trampolines remain; shared and
extracted ownership is direct and genuine cross-boundary validators are named
explicitly; focused, broader, and export checks pass; and bounded review finds
no blocker.

Outcome:
Pending.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Provider-counteroffer-summary callback collapse published as `e30f9090`:
`schema.ex` fell from 11,297 to 11,185 lines and the summary owner from 783 to
669. The 27-entry factory and 12 orphan forwarders disappeared. Two hundred
four focused, 1,340 attributable broader, and 24 export tests passed; compile,
regeneration, xref, format, diff hygiene, and bounded review were clean.

Blocked:
No.
