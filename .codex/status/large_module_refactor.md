# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Relay-data-path-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 16-entry `RelayDataPathSummaryContracts` keyword bag with direct
shared owners, preserve the historical implicit equality-message compatibility,
and relocate relay-data-path model-limit ownership out of `schema.ex`.

Why this slice:
Live inventory leaves `schema.ex` at 10,713 lines. The 439-line relay summary
owner routes 16 primitive, collection, stable-ID, and capability dependencies
through lookup/apply. Every dependency already has an extracted owner; only the
facade's `/5` equality compatibility semantics must be retained explicitly.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all relay-data-path-summary fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/relay_data_path_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused relay-data-path/link-capacity and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No relay-data-path-summary keyword bag or lookup/apply trampolines remain; its
validators and capability are direct, implicit equality messages remain exact,
JSON schema reuses the relocated model-limit owner, focused/broader/export
checks pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Link-capacity-summary callback collapse published as `fc0fc343`: `schema.ex`
fell from 10,749 to 10,713 lines and the owner from 501 to 431; the 16-entry
factory, lookup/apply trampolines, wrappers, and duplicate capability helper
disappeared. Four hundred eighty-seven attributable focused, 1,340 attributable
broader, and 24 export tests passed; compile, regeneration, xref, format, diff
hygiene, and bounded review were clean.

Blocked:
No.
