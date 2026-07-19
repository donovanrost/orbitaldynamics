# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest field-reference extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract exported-schema traversal, field row construction, required
alternatives, stable-identifier classification, trust-boundary source
classification, and identity-policy projection into
`OrbitalDynamics.Study.Manifest.FieldReference`. Keep `field_reference/0` as
the public Manifest facade and pass its schema and facade-owned report metadata
into the dedicated owner.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,825 lines, immediately behind
  the other active production hotspots.
- The selected public builder at 339-362 and private schema-walking helper
  family at 610-799 have no callers outside `field_reference/0`.
- JSON Schema construction, manifest parsing, validation, supported capability
  data, and public CLI-facing commands remain in the Manifest facade.
- Dedicated manifest-reference task tests exercise filtering, field metadata,
  stable identifiers, trust boundaries, and deterministic exported rows.

Verification:
Pending: focused manifest-reference baseline, exact old/new field-reference
artifact, strict compile, manifest validation/schema coverage, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
MissionPlan.Activity precondition-summary extraction, selected in `2bcf1229`
and implemented in `437652a8`. `mission_plan/activity.ex` moved from 5,169 to
4,841 lines; the dedicated owner is 367 lines.

Next candidate:
Re-inventory remaining Study.Manifest schema, scenario, and source-normalization
families after field-reference generation has one production owner.

Blocked:
No.
