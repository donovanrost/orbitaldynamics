# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence import handoff test family split.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema candidate-refresh provenance test family split, selected in `54c572f8`
and implemented in `eaa19f44`. The 3,778-line ledger now exposes four
independently runnable source-report contract families.

Next candidate:
Implement and verify the selected Cadence import handoff test-family split.

Blocked:
No.
