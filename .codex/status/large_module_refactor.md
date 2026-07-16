# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar-report callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the schema-owned 32-function callback bag and all callback adapters
  from station-calendar-report validation.
- The report module now directly uses primitive, stable-ID, collection,
  aggregation, and BranchEvent validation owners; report model and model limits
  cross the boundary as explicit data.
- Preserved nil/non-map behavior and the legacy `must equal #{expected}` default
  equality message with focused regression coverage.
- Reduced `schema.ex` from 13,053 to 13,008 lines and station-calendar-report
  contracts from 1,077 to 880 lines.
- Published implementation commit `20a5a0bd`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused equality-message, communications-fixture, station-provider, curated
  validation, and station-calendar runtime coverage passed (19 plus 42 tests;
  excluded tests were not run).
- Deterministic schema export coverage passed (3 tests).
- The read-only reviewer found no issues and independently passed 58 focused
  equality, station-calendar, station-provider, and nested campaign tests.
- Full schema export left `schemas/` unchanged; the SHA-256 over
  `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused station-calendar/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
- Contact-contention-report callback ownership audit. Four schema delegates
  share a 30-function bag with a 1,158-line module. Primitive, stable-ID, and
  collection owners are directly available; the next slice should first map the
  seven schema-local domain validators and preserve the existing default
  equality-message behavior before choosing a full or phased bag removal.

Blocked:
No.
