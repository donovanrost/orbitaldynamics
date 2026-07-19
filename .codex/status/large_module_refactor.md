# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation validation extraction.

Status:
Selected; implementation has not started.

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
Pending: focused station-provider baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, schema export checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema contact-allocation validation extraction, selected in `c862c76e` and
implemented in `90c1d4c3`. `schema.ex` moved from 7,040 to 7,037 lines; the
dedicated owner is 118 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after station
reservation validation has one production owner.

Blocked:
No.
