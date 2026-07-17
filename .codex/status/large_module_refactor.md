# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review-package callback-bag and scalar-count metadata ownership collapse.

Status:
Implemented, verified, reviewed, and ready to publish.

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
The callback bag now contains only the four genuine Schema-domain validators;
15 shared primitive dependencies and their lookup/apply wrappers became direct
owner calls. The owner now owns the exact required and optional scalar-count
lists, and Schema JSON generation consumes its combined list. Three orphaned
Schema imports, the field-group helper, and two equality shims disappeared.
Review caught an implicit equality-message regression; the exact local shim was
restored in the owner and an assertion now guards `"must equal 1"`. `schema.ex`
fell from 10,179 to 10,100 lines and the owner from 339 to 297, for a net code
reduction of 121 lines (120 including the one-line test strengthening).

Verification gaps:
- Full repository suite not run. The broader regression remains at the
  baseline-proven 1,340/1,345 result with the same five unrelated
  campaign-planner failures.

Last completed slice:
Operator-review-package callback and metadata ownership collapse, publication
pending: 201 focused and 24 export tests passed; the broader suite produced the
baseline-proven 1,340/1,345 result. Compile, checked-in export regeneration,
compile-connected xref, format, diff hygiene, and bounded re-review were clean.

Blocked:
No.
