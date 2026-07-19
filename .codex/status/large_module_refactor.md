# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest routing extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,843 files and warnings as errors.
- Six focused routing/contract tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- Executable before/after proofs matched 344 routes: all 64 declared source
  contracts in string/atom form, all 13 model-only routes, wrappers, version
  shapes, explicit options, pass-through manifests, and error fallbacks.
- Formatting, tracked/untracked diff checks passed, and no proof files remain.
- Static ownership checks confirmed one public `manifest/2` facade and exactly
  179 clauses in the dedicated router.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `manifest_router.ex`.
- Bounded local review found and fixed only migration mechanics: multiline
  callback arguments, used callback names, and atom-key pipeline argument
  order. No pattern order, normalization, dispatch target, option, diagnostic,
  public API, artifact, or schema changes remain.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest routing extraction, selected in `dc7d43b2` and
implemented in `ee8f7b3a`. `cadence_import.ex` moved from 2,056 to 1,415 lines;
the dedicated router is 1,640 lines.

Next candidate:
Re-inventory remaining private row/helper ownership after manifest routing has
one production owner.

Blocked:
No.
