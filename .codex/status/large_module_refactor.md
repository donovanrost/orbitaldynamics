# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport campaign review-package import extraction.

Status:
Completed and published.

Selected boundary:
Extract the candidate-refresh and campaign-repair review-package constructor
implementations into
`OrbitalDynamics.CadenceImport.CampaignReviewPackageImport`. Preserve both
public facade entry points and pass the existing review-package import seam as
a callback.

Selection evidence:
- `cadence_import.ex` is now 2,193 lines.
- The selected pair spans about 50 lines around the custom strategy constructor
  and shares embedded-package precedence and generation-contract routing.
- The pair has one responsibility: turn candidate-refresh and repair artifacts
  into review-package imports while preserving refresh/repair provenance.
- Public API docs, V1 campaign and V3 strategy row construction, manifest
  assembly, schemas, and activity/result imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,839 files and warnings as errors.
- Two focused generation tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched 16 cases across both constructors,
  including embedded packages and the distinct explicit-ID behavior.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both public facade entry points delegate to
  one implementation owner.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `campaign_review_package_import.ex`.
- Bounded local review found no embedded-package precedence, normalization,
  refresh/repair identity, provenance, source-contract, public API, row,
  ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport campaign review-package import extraction, selected in
`072075ce` and implemented in `e761b39b`. `cadence_import.ex` moved from 2,193
to 2,170 lines; the extracted owner is 46 lines.

Next candidate:
Re-inventory V1 campaign/V3 strategy or manifest routing after generation
review-package imports have one production owner.

Blocked:
No.
