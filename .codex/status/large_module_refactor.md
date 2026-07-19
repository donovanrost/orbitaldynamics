# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-planning import extraction.

Status:
Completed and published.

Selected boundary:
Extract the link-capacity, contact-allocation report, capacity-pack summary,
reservation-conflict summary, and standalone contact-intent constructor
implementations into `OrbitalDynamics.CadenceImport.ContactPlanningImport`.
Preserve all five public facade entry points and pass the existing
review-package import seam as a callback.

Selection evidence:
- `cadence_import.ex` is now 2,352 lines.
- The selected contiguous family spans about 80 lines and owns contact
  capacity, allocation, conflict, and intent normalization and routing.
- The family has one responsibility: turn contact-planning evidence into
  review-package imports while preserving the intent activity-ID fallback.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  station/resource-projection imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,834 files and warnings as errors.
- Four focused contact-planning tests passed with 68 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 30 cases across all five
  constructors, three key/source-ID shapes, and inferred versus explicit IDs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all five public facade entry points
  delegate to one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `contact_planning_import.ex`.
- Bounded local review found no normalization, source-ID precedence or
  fallback, OperatorReview conversion, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport contact-planning import extraction, selected in `51ef8061` and
implemented in `9c2864d2`. `cadence_import.ex` moved from 2,352 to 2,321 lines;
the extracted owner is 89 lines.

Next candidate:
Re-inventory remaining public routing after contact-planning imports have one
production owner.

Blocked:
No.
