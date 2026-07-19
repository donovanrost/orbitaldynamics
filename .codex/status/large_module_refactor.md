# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest routing extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract all 179 `manifest/2` pattern clauses into
`OrbitalDynamics.CadenceImport.ManifestRouter`. Preserve `manifest/2` as the
public facade, pass constructor dispatch and unsupported-contract handling as
callbacks, and keep every `from_*` public constructor on the facade.

Selection evidence:
- `cadence_import.ex` is now 2,056 lines.
- The selected multimethod spans 691 lines, contains 179 pattern clauses, and
  routes to 64 constructor names plus pass-through/error fallbacks.
- The family has one responsibility: classify supported wrapper, schema,
  version, and model shapes and dispatch to the stable public constructors.
- Constructor behavior, capability data, diagnostics wording, row builders,
  manifest assembly, and schemas remain outside the boundary.

Verification:
Pending: focused routing baselines, exhaustive old/new routing proof, strict
compile, all combined CadenceImport tests, schema contracts, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport standalone proposed-contact import extraction, selected in
`31ca7a2d` and implemented in `b300f602`. `cadence_import.ex` moved from 2,068
to 2,056 lines; the extracted owner is 25 lines.

Next candidate:
Re-inventory remaining private row/helper ownership after manifest routing has
one production owner.

Blocked:
No.
