# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport standalone proposed-contact import extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,842 files and warnings as errors.
- One focused proposed-contact test passed with 71 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An executable before/after proof matched six complete manifests across
  empty, string-keyed, atom-keyed, inferred-ID, and explicit-ID inputs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the public facade entry point delegates to
  one implementation owner and the facade's final generic option helper was
  retired.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `proposed_contact_import.ex`.
- Bounded local review found no normalization, row rank/shape, provenance,
  context, source-ID, public API, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport standalone proposed-contact import extraction, selected in
`31ca7a2d` and implemented in `b300f602`. `cadence_import.ex` moved from 2,068
to 2,056 lines; the extracted owner is 25 lines.

Next candidate:
Select the manifest routing extraction after standalone proposed-contact import
has one production owner.

Blocked:
No.
