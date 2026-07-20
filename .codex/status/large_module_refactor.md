# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema fallback property-schema extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the fallback JSON Schema property construction and its contract
constant/stable-ID decoration rules from Schema into one focused schema-owner
module. Keep dispatch order and specialized property providers in the facade.
Preserve field-type hints, stable-ID matching, descriptions, public Schema
APIs, generated JSON Schema, executable validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,982 lines; the other
  targeted public facades are now 164 to 524 lines.
- The fallback builder is one cohesive responsibility: infer the coarse type,
  add contract identity constants, and add stable-ID patterns.
- Its implementation occupies 34 non-contiguous facade lines but has only one
  call site and explicit inputs for field hints and the stable-ID pattern.
- Specialized property dispatch and context-bearing shared-schema wrappers
  remain out of scope.
- Exact fallback schemas and every checked-in export must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common string-array eager routing, selected in `b6a13f21` and
implemented in `568cff53`.
`schema.ex` moved from 5,986 to 5,982 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
