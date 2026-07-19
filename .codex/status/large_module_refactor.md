# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest field-reference extraction.

Status:
Completed and pushed in `5a432b81`.

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
- Strict warnings-as-errors compile passed across 3,877 files.
- Focused manifest-reference CLI coverage passed: 9 tests.
- Adjacent validation-fixture, schema-lint, and JSON Schema export coverage
  passed: 29 tests.
- Exact old/new public artifact comparison against `aeb6e003` passed for the
  complete 4,120-row field reference.
- Runtime xref found the new owner referenced only by the Manifest facade;
  static single-ownership review and `git diff --check` passed.
- `study/manifest.ex` moved from 4,825 to 4,613 lines; the dedicated owner is
  241 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest field-reference extraction, selected in `aeb6e003` and
implemented in `5a432b81`. `study/manifest.ex` moved from 4,825 to 4,613
lines; the dedicated owner is 241 lines.

Next candidate:
Re-inventory remaining Study.Manifest schema, scenario, and source-normalization
families after field-reference generation has one production owner.

Blocked:
No.
