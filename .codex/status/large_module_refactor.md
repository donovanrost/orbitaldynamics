# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest validation-error extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract manifest validation reason-to-error rendering, field/option path
selection, JSON-safe detail normalization, and fallback error construction into
`OrbitalDynamics.Study.Manifest.ValidationError`. Preserve the existing
private `manifest_error/1` seam in the Manifest facade and pass the
facade-owned schema version into the dedicated owner.

Selection evidence:
- `study/manifest.ex` remains a production hotspot at 4,613 lines after the
  field-reference extraction.
- The selected 384-507 helper family is closed behind the two
  `manifest_error/1` call sites in `validation_report/1`.
- File reading, JSON decoding, semantic validation, report assembly, and
  schema metadata remain in the Manifest facade.
- Focused Manifest tests assert deterministic error codes, paths, messages,
  details, and valid/invalid report status.

Verification:
Pending: focused Manifest baseline, exact old/new public validation reports,
strict compile, adjacent lint/schema coverage, static single ownership,
runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest field-reference extraction, selected in `aeb6e003` and
implemented in `5a432b81`. `study/manifest.ex` moved from 4,825 to 4,613
lines; the dedicated owner is 241 lines.

Next candidate:
Re-inventory remaining Study.Manifest schema, scenario, and source-normalization
families after validation errors have one production owner.

Blocked:
No.
