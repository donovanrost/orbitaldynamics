# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Link-capacity-report callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 21-function callback bag and adapters from link-capacity report,
  row, count, and assumptions validation.
- The family now directly uses primitive, stable-ID, row, and execution-metric
  owners; its optional stable-ID-array-map composite remains local.
- Moved generic optional-list equality from `schema.ex` into
  `PrimitiveValidation` unchanged.
- Both schema delegates now call direct family arities.
- Reduced `schema.ex` from 12,930 to 12,875 lines and link-capacity-report
  contracts from 1,137 to 910 lines.
- Published implementation commit `012a6458`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused link-capacity runtime, communications-fixture, curated validation, and
  nested campaign coverage passed: 51 tests, 180 excluded.
- Deterministic schema export coverage passed: 3 tests.
- The read-only reviewer found no issues and independently passed focused count,
  assumption, and optional-list validation coverage.
- Full schema export left `schemas/` unchanged; the SHA-256 over
  `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run.
- The previously reproduced contact-allocation overlap-count nil-message failure
  remains baseline debt and is unrelated to this slice.

Next candidate:
- Contact-allocation-summary callback ownership audit. Its sole schema delegate
  feeds a 57-function bag into a 1,515-line module. Generic validators already
  have direct owners, and the domain half maps to ContactAllocation capabilities
  plus public `ContactAllocationReportContracts` helpers; the next slice should
  verify those mappings before choosing full or phased bag removal.

Blocked:
No.
