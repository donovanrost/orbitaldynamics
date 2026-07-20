# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
No slice selected.

Status:
Slice complete and pushed.

Selected boundary:
Extracted schema-facing resource-filter capability and assumptions access into
`OrbitalDynamics.Schema.ResourceFilterCapabilityContext` and import its focused
internal APIs into the Schema facade.
Preserved all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,451 lines.
- Sixteen private helpers repeatedly query ResourceFilter capabilities for
  model limits, policy/margin/availability aliases, direction metadata,
  identity fields, suppression/review statuses, then assemble the assumptions
  schema.
- The selected code has one responsibility: expose schema-facing
  resource-filter capability context and assumptions with stable ordering.
- The only generic schema dependency is already public as
  `CommonJsonSchema.string_array/0`.
- Importing those internal APIs preserves the existing unqualified call sites
  and evaluation order. Property-dispatch composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact model-limit conversion, capability values and ordering, validation
  results, generated JSON Schema, and checked-in exports must remain unchanged.

Implementation:
- Added the focused `ResourceFilterCapabilityContext` owner for report model
  limits, policy/margin/availability aliases, direction metadata, identity
  fields, suppression/review statuses, and assumptions-schema assembly.
- Imported the two facade-consumed internal APIs into `Schema`, preserving
  property-dispatch call sites and original repeated capability lookups.
- Reused the public `CommonJsonSchema.string_array/0` dependency directly.
- Removed sixteen private capability/assumptions helpers from the facade.
- `schema.ex` moved from 6,451 to 6,361 lines; the owner is 99 lines.

Verification:
- Pre-change strict focused baseline: 22 JSON-export/resource contract tests
  passed.
- Post-change strict focused verification: the same 22 tests passed; the full
  schema-export task test and 7 broader validation/resource fixture tests also
  passed.
- Static checks found no migrated resource-filter capability helpers
  remaining; xref reports `schema.ex` as an exported/imported caller of
  `ResourceFilterCapabilityContext`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,053 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema resource-filter capability-context extraction, selected in `20626595`
and implemented in `4c1eab32`.
`schema.ex` moved from 6,451 to 6,361 lines; the dedicated
ResourceFilterCapabilityContext owner is 99 lines.

Next candidate:
Re-rank the remaining schema capability/model-limit responsibility clusters.

Blocked:
No.
