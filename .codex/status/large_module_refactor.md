# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema embedded-contract JSON Schema extraction.

Status:
Completed and pushed.

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
Added `EmbeddedContractJsonSchema` as the owner of deterministic nested
contract-object assembly. Schema keeps registry lookup and property dispatch
ownership and supplies both through explicit callbacks. `schema.ex` moved from
5,951 to 5,941 lines; the focused owner module is 21 lines.

Verification:
- Strict focused export/communications/feedback/Cadence/review baseline before
  extraction: 34 passed.
- The same strict focused suite after extraction: 34 passed.
- Strict checked-in export, timeline-report, resource, and handoff coverage:
  21 passed.
- The full schema-export task completed and produced no checked-in changes.
- Static inspection confirms required fields remain unchanged while combined
  property keys are still de-duplicated and sorted.
- `mix xref callers OrbitalDynamics.Schema.EmbeddedContractJsonSchema` reports
  only the expected Schema facade runtime caller.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files.
- Implementation commit `fdec7bff` pushed to `main`.

Behavior/schema changes:
None. Required/optional handling, deterministic property ordering, property
dispatch, public Schema APIs, executable validation, and checked-in exports
remain unchanged.

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
