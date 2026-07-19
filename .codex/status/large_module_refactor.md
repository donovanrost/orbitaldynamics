# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest validation-error extraction.

Status:
Completed and pushed in `3cf172e6`.

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
- Strict warnings-as-errors compile passed across 3,878 files.
- Focused Study.Manifest coverage passed: 42 tests.
- Adjacent manifest-lint and validation-fixture coverage passed: 9 tests.
- Exact old/new public validation-report comparison against `8fde79c4` passed
  for 8 missing, unsupported, malformed JSON, non-object JSON, and file-error
  cases.
- Runtime xref found the new owner referenced only by the Manifest facade;
  static single-ownership review and `git diff --check` passed.
- `study/manifest.ex` moved from 4,613 to 4,489 lines; the dedicated owner is
  127 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest validation-error extraction, selected in `8fde79c4` and
implemented in `3cf172e6`. `study/manifest.ex` moved from 4,613 to 4,489 lines;
the dedicated owner is 127 lines.

Next candidate:
Re-inventory remaining Study.Manifest schema, scenario, and source-normalization
families after validation errors have one production owner.

Blocked:
No.
