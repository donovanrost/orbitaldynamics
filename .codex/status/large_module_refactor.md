# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-source validation extraction.

Status:
Completed and published in `abaa5617`.

Selected boundary:
Extract optional timeline diff, dependency-impact, activity-precondition,
integrity, preservation, lifecycle, and activity-state source validation into
`OrbitalDynamics.Schema.TimelineSourceValidation`. Preserve the existing
private `Schema` callback seams as thin delegates.

Selection evidence:
- `schema.ex` is 7,204 lines; the selected contiguous cluster spans
  6,183-6,337.
- The cluster has one responsibility: validate optional timeline-family source
  artifacts embedded in handoff and summary rows.
- Its dependencies are existing timeline contract modules, primitive errors,
  and capability-derived timeline/timeline-feedback model limits.
- Transition-application validation, registry data, JSON Schema export,
  contract dispatch, and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,857 files with warnings as errors.
- All 26 focused timeline-summary and activity-state tests passed.
- All 175 split Schema contract tests passed with warnings as errors.
- All 15 JSON-export contract tests passed.
- Exact old/new executable comparison passed for 20 valid and intentionally
  invalid checked-in timeline reports.
- A whitespace-normalized mechanical comparison confirmed the new owner
  preserves all eight selected multi-clause validators.
- Static ownership confirms one timeline-source validation owner with eight
  required private Schema callback seams.
- Runtime xref, format, diff checks, and bounded review passed.
- `schema.ex` moved from 7,204 to 7,141 lines; the new owner is 135 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-source validation extraction, selected in `6d33c608` and
implemented in `abaa5617`. `schema.ex` moved from 7,204 to 7,141 lines; the
dedicated owner is 135 lines.

Next candidate:
Re-inventory remaining Schema transition-application and family-validation
clusters after timeline-source validation has one production owner.

Blocked:
No.
