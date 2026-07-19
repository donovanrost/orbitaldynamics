# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest-contract diagnostic extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,815 files and warnings as errors.
- Two focused capability and unsupported-input tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 10-case direct decision matrix covered binary, atom-key/value, missing,
  nil/null, empty-string, numeric, and collection contract labels plus ordered
  and empty supported-source lists.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both diagnostic formatters have one
  production implementation behind the preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `manifest_contract_diagnostics.ex`.
- Bounded local review found no capability ownership, normalization, inspection,
  list order, error-message, dispatch, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest-contract diagnostic extraction, selected in `1a983a0c`
and implemented in `580eb142`. `cadence_import.ex` moved from 3,349 to 3,341
lines; the extracted owner is 20 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after manifest-contract diagnostics have one production owner.

Blocked:
No.
