# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport capability ownership extraction.

Status:
Completed and pushed in `7d081341`.

Selected boundary:
Extract the full capability declaration, schema contract/version, accepted
manifest statuses, Cadence source statuses, and source-review-type composition
into `OrbitalDynamics.CadenceImport.Capability`. Preserve the public
`capability/0` and `capabilities/0` facade API, and have manifest assembly read
the same owner instead of duplicating policy constants.

Selection evidence:
- `cadence_import.ex` is now 866 lines.
- Capability metadata and its source/status constants occupy roughly 200 lines
  at the top of the facade.
- The metadata is one responsibility and is consumed by the public capability
  API, manifest builder configuration, review-package configuration, and
  supported-contract diagnostics.
- Public constructors, row builders, routing, manifest assembly behavior, and
  schemas remain outside the boundary.

Verification:
- Strict warnings-as-errors compile passed across 3,846 files.
- Three focused capability/schema/manifest tests passed.
- All 96 combined CadenceImport tests passed.
- All four CadenceImport schema-contract tests passed.
- Exact old/new comparison passed for both complete public capability maps and
  four representative direct/routed campaign and strategy manifests.
- Static search confirms schema contract/version and accepted statuses have one
  capability owner while the facade preserves both public capability APIs.
- Runtime xref confirms the facade owns the dependency on the capability owner.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport capability ownership extraction, selected in `ace1eb07` and
implemented in `7d081341`. `cadence_import.ex` moved from 866 to 663 lines; the
dedicated capability owner is 216 lines.

Next candidate:
Re-inventory the remaining generic facade orchestration seams after capability
metadata has one production owner.

Blocked:
No.
