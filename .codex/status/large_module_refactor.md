# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation-report generic callback ownership phase.

Status:
Complete; ready to publish.

Result:
- Removed 39 generic primitive, stable-ID, collection, and aggregation entries
  from the 51-entry contact-allocation-report callback bag.
- Renamed the remaining 12-entry bag to describe its nested-report, row,
  capacity-group, and domain-contract responsibility across five schema call
  sites.
- Moved number-field equality and non-negative-number-map validation into the
  shared primitive owner unchanged; removed five newly unused schema
  aggregation adapters.
- Preserved all public schema and contact-allocation-report function signatures.
- Reduced `schema.ex` from 12,875 to 12,788 lines and the report contracts module
  from 2,001 to 1,687 lines.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused runtime/default-message/curated validation coverage passed 25/26; the
  only failure was the previously reproduced line-1247 overlap-count baseline.
- Full contact-allocation coverage passed 69/70 with only that same baseline.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue, and `git diff --check` passed.
- The read-only reviewer found no code issues and independently passed compile,
  8 focused contract tests, and 4 public-facade/curated validation tests.

Verification gaps:
- Full repository suite not run.
- `test/orbital_dynamics/communications/contact_allocation_test.exs:1247`
  still expects `must equal 2` but receives a nil message; this was previously
  reproduced on published HEAD and is unrelated baseline debt.

Last commit:
Pending publication; prior handoff `697d2363`.

Next candidate:
- Contact-allocation-summary generic callback ownership phase. Its 1,515-line
  module still receives a broad callback bag combining generic validation with
  capabilities and contact-allocation-report domain functions. First remove
  generic primitive/collection callbacks through their existing owners while
  preserving the capability and report-domain boundary.

Blocked:
No.
