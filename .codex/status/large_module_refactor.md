# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence import handoff test family split.

Status:
Completed and verified.

Selected boundary:
Split the 1,597-line Cadence source-window handoff test into independently
runnable basic import, lineage/resource, battery-flow, embedded-source-report,
and nested review-copy families. Keep every mutation/path assertion and the
checked-in manifest reader in the same contract module.

Selection evidence:
- The self-contained restart points begin at `invalid_scalar_count`,
  `battery_handoff_manifest`, `source_timeline_diff_row`, and
  `invalid_review_copy_lineage`.
- Each section depends only on a fresh copy of
  `cadence_import_manifest_v1.json`; section-local rows and indexes do not cross
  those boundaries.
- Separate tests make failures attributable to one handoff family without
  replacing the exhaustive negative-path coverage.

Implementation:
Selected in `e9a912b0` and implemented in `7ff0286b`. Split the source-window
handoff ledger into basic import, lineage/resource, battery-flow,
embedded-source-report, and nested review-copy tests. Each family reloads its
checked-in fixture context; the review-copy family reloads the seven source rows
whose nested copies it validates. All original mutation/path assertions remain.

Verification:
- The focused Cadence import module passed with warnings as errors: 8 tests.
- The full schema/validation gate passed with warnings as errors: 368 tests.
- Full checked-in schema export regeneration produced no diff.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format and `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema Cadence import handoff test family split, selected in `e9a912b0` and
implemented in `7ff0286b`. The 1,597-line catch-all handoff test now exposes
five independently runnable responsibility families.

Next candidate:
Inspect the contact-feedback and operator-review schema contract modules for
the next independently runnable family boundary.

Blocked:
No.
