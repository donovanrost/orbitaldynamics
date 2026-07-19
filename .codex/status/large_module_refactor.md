# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport V1 campaign artifact orchestration extraction.

Status:
Completed and published.

Selected boundary:
Extract the V1 campaign artifact constructor orchestration into
`OrbitalDynamics.CadenceImport.CampaignArtifactImport`. Preserve
`from_campaign_artifact/2` as the public facade and pass its existing proposed
contact row, review-row, and manifest-builder seams as callbacks.

Selection evidence:
- `cadence_import.ex` is now 2,122 lines.
- The selected constructor spans about 70 lines and coordinates proposed
  contact ordering, selected review-row composition, provenance, and context.
- Its responsibility is orchestration; concrete proposed-contact/review row
  builders and manifest assembly already have separate owners.
- Public API docs, standalone proposed-contact construction, schemas, and
  V2/V3 generation imports remain outside the boundary.

Verification:
- Strict test compile passed with 3,841 files and warnings as errors.
- Two focused campaign tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched six complete manifests across
  empty, string-keyed, atom-keyed, inferred-ID, and explicit-ID inputs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the public facade entry point delegates to
  one orchestration owner and the stale summary-context facade seam was
  retired.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `campaign_artifact_import.ex`.
- Bounded local review found no proposed-contact ordering, accepted review-type
  set, review ordering, provenance, source-ID, public API, row, or schema
  changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport V1 campaign artifact orchestration extraction, selected in
`81c45f3b` and implemented in `cedcccc5`. `cadence_import.ex` moved from 2,122
to 2,068 lines; the extracted owner is 72 lines.

Next candidate:
Re-inventory standalone proposed-contact construction or manifest routing after
V1 campaign orchestration has one production owner.

Blocked:
No.
