# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-contention-report callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the shared 30-function callback bag and adapters from report, group,
  resolution-report, recommendation, policy, and deferred-priority validation.
- The family now directly uses primitive, stable-ID, row, execution-metric, and
  priority-override owners; its invalid-contact review-status rule stays local.
- Moved generic row-multiset validation to `CollectionValidation` and shared
  priority-field evidence validation to `PriorityOverrideContracts` unchanged.
- Preserved default equality messages with focused regression coverage.
- Reduced `schema.ex` from 13,008 to 12,930 lines and contact-contention-report
  contracts from 1,158 to 928 lines.
- Published implementation commit `383cf4d7`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused equality-message, contact-contention runtime, communications-contract,
  and curated validation coverage passed: 59 tests, 179 excluded.
- Deterministic schema export coverage passed: 3 tests.
- The read-only reviewer found no issues and independently passed 20 focused
  equality, communications, and curated validation tests.
- Full schema export left `schemas/` unchanged; the SHA-256 over
  `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run.
- Adjacent `contact_allocation_test.exs` remains 71/72: the existing
  station-calendar overlap-count assertion receives a nil message instead of
  `must equal 2`. The same failure reproduced at published `HEAD` in an isolated
  worktree, so it is baseline debt rather than a regression from this slice.

Next candidate:
- Link-capacity-report callback ownership cleanup. Two schema delegates share a
  21-function bag with a 1,137-line module; all entries have direct primitive,
  stable-ID, collection, and execution-metric owners, with only the existing
  optional stable-ID-array-map composite needing to remain local.

Blocked:
No.
