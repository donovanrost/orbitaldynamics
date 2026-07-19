# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport standalone proposed-contact import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the standalone proposed-contact constructor implementation into
`OrbitalDynamics.CadenceImport.ProposedContactImport`. Preserve
`from_proposed_contact/2` as the public facade and pass its existing row and
manifest-builder seams as callbacks.

Selection evidence:
- `cadence_import.ex` is now 2,068 lines.
- The selected constructor spans about 30 lines and is the final non-router
  public constructor still assembling a manifest directly on the facade.
- Its responsibility is standalone proposed-contact provenance/context;
  concrete row construction and manifest assembly already have owners.
- Public API docs, schemas, campaign orchestration, and manifest routing remain
  outside the boundary.

Verification:
Pending: focused proposed-contact baseline, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport V1 campaign artifact orchestration extraction, selected in
`81c45f3b` and implemented in `cedcccc5`. `cadence_import.ex` moved from 2,122
to 2,068 lines; the extracted owner is 72 lines.

Next candidate:
Select the manifest routing extraction after standalone proposed-contact import
has one production owner.

Blocked:
No.
