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
Extracted schema-facing contact-filter capability and assumptions access into
`OrbitalDynamics.Schema.ContactFilterCapabilityContext` and import its focused
internal APIs into the Schema facade.
Preserved all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,498 lines.
- Nine private helpers repeatedly query ContactFilter capabilities for model
  limits, suppression metadata, station/capacity precedence and aliases, then
  assemble the report assumptions schema.
- The selected code has one responsibility: expose schema-facing
  contact-filter capability context and assumptions with stable ordering.
- Importing those internal APIs preserves the existing unqualified call sites
  and evaluation order. Property-dispatch composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact model-limit conversion, capability values and ordering, validation
  results, generated JSON Schema, and checked-in exports must remain unchanged.

Implementation:
- Added the focused `ContactFilterCapabilityContext` owner for report model
  limits, suppression metadata, station/capacity precedence and aliases, and
  assumptions-schema assembly.
- Imported the two facade-consumed internal APIs into `Schema`, preserving
  property-dispatch call sites and the original repeated capability lookups.
- Removed nine private capability/assumptions helpers from the facade.
- `schema.ex` moved from 6,498 to 6,451 lines; the owner is 56 lines.

Verification:
- Pre-change strict focused baseline: 30 JSON-export/communications/resource
  contract tests passed.
- Post-change strict focused verification: the same 30 tests passed; the full
  schema-export task test and 6 broader validation/filter fixture tests also
  passed.
- Static checks found no migrated contact-filter capability helpers remaining;
  xref reports `schema.ex` as an exported/imported caller of
  `ContactFilterCapabilityContext`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,052 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-filter capability-context extraction, selected in `262e24ae`
and implemented in `817355a0`.
`schema.ex` moved from 6,498 to 6,451 lines; the dedicated
ContactFilterCapabilityContext owner is 56 lines.

Next candidate:
Re-rank the remaining schema capability/model-limit responsibility clusters.

Blocked:
No.
