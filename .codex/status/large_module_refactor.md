# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row builder extraction.

Status:
Completed and pushed in `540325fc`.

Selected boundary:
Extract `review_manifest_row/2`, its 36-type callback registry, all
review-specific row adapter functions, and their private normalization/context
helpers into `OrbitalDynamics.CadenceImport.ReviewRowBuilder`. Preserve one
private facade seam used by review-package and campaign/strategy orchestration.

Selection evidence:
- `cadence_import.ex` is now 1,415 lines.
- The selected cluster spans roughly 500 lines and wires 36 review types to
  family-specific row modules plus shared normalization/context policies.
- The cluster has one responsibility: construct one manifest row from one
  normalized operator-review row and rank.
- Campaign proposed-contact/strategy rows, public constructors, manifest
  routing, manifest assembly, capability data, and schemas remain outside the
  boundary.

Verification:
- Strict warnings-as-errors compile passed across 3,844 files.
- Three representative focused review-row tests passed.
- All 96 combined CadenceImport tests passed.
- All four CadenceImport schema-contract tests passed.
- Exact old/new public-manifest comparison passed for all 36 explicit review
  adapters and all 10 accepted generic/fallback review types, both as 46
  individual packages and one combined package.
- Static search confirms one private facade seam and one public builder owner.
- Runtime xref confirms the facade owns the dependency on the new builder.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row builder extraction, selected in `5cf4c17c` and
implemented in `540325fc`. `cadence_import.ex` moved from 1,415 to 907 lines;
the dedicated builder is 537 lines.

Next candidate:
Re-inventory the remaining campaign/strategy facade callback adapters,
especially proposed-contact and strategy-row construction plus their shared
normalization/context callbacks.

Blocked:
No.
