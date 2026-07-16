# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation-acceptance callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 16-function validation-acceptance facade bag and all callback
  arguments/application wrappers from `ValidationAcceptanceReportContracts`.
- Model-acceptance and safety-case validation now directly use primitive,
  collection, stable-ID, and validation-record owners; model limits stay
  explicit.
- Preserved the public schema validation/report facade.
- Reduced `schema.ex` from 13,205 to 13,181 lines and validation-acceptance
  contracts from 894 to 773 lines.
- Published implementation commit `8f346631`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Full validation-policy contract plus deterministic and checked-in export
  coverage: 3 passed, 1 excluded.
- Runtime probes preserved exact row-derived status counts, model limits,
  validation-record shape/ID consistency, and nested stable-ID diagnostics.
- Full schema export left `schemas/` unchanged; contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run. Malformed non-map safety-case evidence still reaches the
  family's pre-existing downstream `BadMapError`; this ownership-only slice did
  not alter that behavior.

Next candidate:
- Command-window-report callback ownership cleanup. Its sole schema caller
  feeds a 17-function bag into a 334-line family module, with primitive,
  collection, stable-ID, activity-context, and interval owners available.

Blocked:
No.
