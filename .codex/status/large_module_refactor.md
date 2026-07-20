# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema embedded-contract JSON Schema extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract deterministic embedded-contract JSON Schema assembly from Schema into
one focused schema-owner module. Keep registry access and property dispatch in
the facade through explicit callbacks. Preserve required/optional field
handling, field ordering, public Schema APIs, generated JSON Schema, executable
validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,951 lines; the other
  targeted public facades are now 164 to 524 lines.
- The embedded builder is one cohesive responsibility: load one contract,
  combine required and optional fields, de-duplicate and sort them, and build
  their nested properties.
- It has one facade call site and clean callback boundaries for contract lookup
  and property dispatch.
- Specialized property dispatch, registry ownership, and context-bearing
  shared-schema wrappers remain out of scope.
- Exact embedded schemas and every checked-in export must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema fallback property-schema extraction, selected in `a62a7724` and
implemented in `e07edb8c`.
`schema.ex` moved from 5,982 to 5,951 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
