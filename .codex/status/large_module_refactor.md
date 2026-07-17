# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review-package callback-bag and scalar-count metadata ownership collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 19-entry operator-review-package keyword bag with direct shared
primitive validation while retaining only the four Schema-domain validator
hooks; move required and optional scalar-count field metadata into the package
owner so executable validation and JSON-schema generation share one source.

Why this slice:
Live inventory leaves `schema.ex` at 10,179 lines. The 339-line package owner
routes 15 shared primitives through lookup/apply wrappers, while its 42 scalar
count fields remain split into Schema-owned lists consumed by both validation
and JSON generation. Four nested domain validators genuinely remain facade
context and define a small explicit callback boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all operator-review-package fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operator_review_package_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused operator-review-package/operator-review/schema tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
Only the four genuine Schema-domain validator hooks remain in the package
callback bag; primitive validation and scalar-count metadata have cohesive
direct owners, exact messages and ordering remain stable, focused/broader/export
checks pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Branch-comparison-report callback and metadata ownership collapse published as
`9f095287`: `schema.ex` fell from 10,280 to 10,179 lines and the owner from 547
to 474, for a net reduction of 174 lines. One hundred ninety-four focused and
24 export tests passed; the broader suite produced the baseline-proven
1,340/1,345 result. Compile, checked-in export regeneration, compile-connected
xref, format, diff hygiene, and bounded review were clean.

Blocked:
No.
