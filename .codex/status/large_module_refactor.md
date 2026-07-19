# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation validation extraction.

Status:
Completed and published.

Selected boundary:
Extract optional station-calendar report validation plus station-reservation
review, hold, and hold-import-readiness summary validation into
`OrbitalDynamics.Schema.StationReservationValidation`. Preserve the existing
arity-2 and arity-3 private Schema seams.

Selection evidence:
- `schema.ex` is 7,037 lines; the selected contiguous cluster spans
  5,964-6,003.
- The cluster has one responsibility: validate station-calendar and
  station-reservation summary artifacts.
- All validators share the same station-calendar model and capability-derived
  model limits, with no facade-owned callback dependency.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,862 files with warnings as errors.
- Focused station-provider contracts passed: 6 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 8 valid and mutated
  station-calendar/reservation fixtures.
- Static inspection confirms the facade retains only its arity-2/arity-3
  callback seams; runtime xref reports `Schema` as the sole caller of the new
  owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema station-reservation validation extraction, selected in `24310979` and
implemented in `de73642a`. `schema.ex` moved from 7,037 to 7,023 lines; the
dedicated owner is 48 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after station
reservation validation has one production owner.

Blocked:
No.
