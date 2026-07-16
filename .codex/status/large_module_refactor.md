# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Activity-template callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 13-function activity-template facade bag and all callback
  arguments and application wrappers from `ActivityTemplateContracts`.
- The family now directly uses primitive, stable-ID, and collection aggregation
  owners; Timeline capabilities are an explicit input.
- Removed five dead schema enum wrappers while preserving the public schema
  validation/report facade.
- Reduced `schema.ex` from 13,245 to 13,205 lines and activity-template
  contracts from 479 to 425 lines.
- Published implementation commit `ccf482ff`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Activity-template contract, deterministic bundle, and checked-in export
  coverage: 3 passed, 5 excluded. The template contract test covers valid
  output plus stable-ID, activity type, field-count/list, default-field,
  metadata, lifecycle, resource, subsystem, and precondition diagnostics.
- Full schema export left `schemas/` unchanged; contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused template/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
- Validation-acceptance callback ownership cleanup. Its two schema call sites
  feed a 16-function bag into an 894-line family module; primitive, collection,
  stable-ID, and validation-record responsibilities already have direct owners.

Blocked:
No.
