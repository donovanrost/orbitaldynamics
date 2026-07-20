# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-level owner routing.

Status:
Selected; implementation not started.

Selected boundary:
Move the validation-level enum schema into `ValidationJsonSchema`, route the
two lazy callbacks and two eager consumers directly to that owner, and remove
the zero-context facade helper. Preserve callback timing, validation-level
names, public Schema APIs, generated JSON Schema, executable validation, and
checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,941 lines; the other
  targeted public facades are now 164 to 524 lines.
- The helper has exactly four consumers and only wraps
  `ValidationPolicyContracts.level_names/0` in a string enum schema.
- `ValidationJsonSchema` already owns the adjacent validation record, evidence,
  batch-entry, and issue schema shapes.
- The owner API can preserve both zero-arity callback timing and eager values.
- Context-bearing validation and CommonJsonSchema helpers remain out of scope.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema embedded-contract JSON Schema extraction, selected in `56099b3f` and
implemented in `fdec7bff`.
`schema.ex` moved from 5,951 to 5,941 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
