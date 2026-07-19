# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest-contract diagnostic extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract unsupported manifest contract labeling and supported-contract list
formatting into `OrbitalDynamics.CadenceImport.ManifestContractDiagnostics`.
Preserve the facade's two existing private diagnostic seams as delegates and
pass the existing capability map into the supported-list formatter.

Selection evidence:
- `cadence_import.ex` is now 3,349 lines.
- The selected contiguous diagnostic family spans about 15 lines and supplies
  the unsupported-input error returned by the manifest facade.
- The family has one responsibility: normalize the reported contract label and
  render the advertised supported-source list without changing capability
  ownership.
- Manifest dispatch, capability construction, row construction, schemas, and
  successful manifest construction remain outside the boundary.

Verification:
Pending: focused capability and unsupported-input baselines, exact diagnostic
decision matrix, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport candidate-diff field policy extraction, selected in `47b70576`
and implemented in `84d11b0a`. `cadence_import.ex` moved from 3,361 to 3,349
lines; the extracted owner is 22 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after manifest-contract diagnostics have one production owner.

Blocked:
No.
