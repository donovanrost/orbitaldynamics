# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-level owner routing.

Status:
Completed and pushed.

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
Added `ValidationJsonSchema.validation_level/0`, routed both lazy callbacks and
both eager consumers directly to that owner, and removed the zero-context
facade helper. `schema.ex` moved from 5,941 to 5,934 lines.

Verification:
- Strict focused JSON Schema export and validation evidence/scoring baseline
  before routing: 24 passed.
- The same strict focused suite after routing: 24 passed.
- Strict checked-in export, validation-policy, and registry-capability
  coverage: 9 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one owner definition, two direct lazy
  callbacks, two direct eager calls, and zero facade helper references.
- `mix xref callers OrbitalDynamics.Schema.ValidationJsonSchema` reports the
  expected Schema facade and internal validation-schema consumers.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files.
- Implementation commit `8ede25ac` pushed to `main`.

Behavior/schema changes:
None. Validation-level names and enum shape, callback timing, public Schema
APIs, executable validation, and checked-in exports remain unchanged.

Last completed slice:
Schema validation-level owner routing, selected in `d84e94f8` and implemented
in `8ede25ac`.
`schema.ex` moved from 5,941 to 5,934 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
