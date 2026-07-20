# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema fallback property-schema extraction.

Status:
Completed and pushed.

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
Added `FallbackPropertyJsonSchema` as the owner of coarse type inference,
contract identity constants, artifact-family constants, and stable-ID pattern
decoration. The facade retains its callback-compatible fallback entry point and
passes the field hints and stable-ID pattern explicitly. `schema.ex` moved from
5,982 to 5,951 lines; the focused owner module is 44 lines.

Verification:
- Strict focused export/communications/feedback/Cadence/review baseline before
  extraction: 34 passed.
- The same strict focused suite after extraction: 34 passed.
- Strict checked-in export, timeline-report, resource, and handoff coverage:
  21 passed.
- The full schema-export task completed and produced no checked-in changes.
- Static inspection confirms the decoration helpers exist only in the focused
  owner and specialized property dispatch remains in the facade.
- `mix xref callers OrbitalDynamics.Schema.FallbackPropertyJsonSchema` reports
  only the expected Schema facade runtime caller.
- `git diff --check` passed.
- Strict forced compile passed across 4,071 files.
- Implementation commit `e07edb8c` pushed to `main`.

Behavior/schema changes:
None. Field-type hints, contract constants and descriptions, artifact-family
constants, stable-ID matching and patterns, public Schema APIs, executable
validation, and checked-in exports remain unchanged.

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
