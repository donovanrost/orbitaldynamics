# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import-row primitive callback-boundary collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 11 shared primitive entries in the Cadence-import-row callback bag
with direct CollectionValidation, PrimitiveValidation, and StableIdValidation
calls while retaining the genuinely Schema-context handoff/domain validators as
the explicit callback boundary.

Why this slice:
Live inventory leaves `schema.ex` at 10,100 lines. The 713-line Cadence import
row owner repeatedly routes common primitive checks through generic lookup/apply
calls across its field groups, while the remaining handoff validators genuinely
depend on facade context. This is a bounded way to shrink both the owner and the
largest facade without pretending the domain boundary has disappeared.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all Cadence-import-manifest row
fields, exact paths/messages/order, consumers, deterministic artifacts, and
schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/cadence_import_row_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused Cadence-import-manifest/operator-review/schema tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No shared primitive remains in the Cadence-import-row callback bag or generic
lookup/apply route; the domain callback boundary remains explicit, exact
messages and ordering remain stable, focused/broader/export checks pass, and
bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Operator-review-package callback and metadata ownership collapse published as
`03a8a709`: `schema.ex` fell from 10,179 to 10,100 lines and the owner from 339
to 297, for a net code reduction of 121 lines. Two hundred one focused and 24
export tests passed; the broader suite produced the baseline-proven 1,340/1,345
result. Compile, checked-in export regeneration, compile-connected xref, format,
diff hygiene, and bounded re-review were clean.

Blocked:
No.
