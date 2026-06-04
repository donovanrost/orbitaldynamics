# Schema Validation Report

`OrbitalDynamics.Schema.validation_report/2` and
`mix orbital_dynamics.schema.lint --format json` build
`schema_validation_report.v1` wrappers around executable artifact validation.
`mix orbital_dynamics.schema.lint --output <path>` writes the same wrapper as a
checked import-gate artifact before returning success or raising on failures.
`mix orbital_dynamics.schema.lint --all --input-dir <dir>` writes or prints a
`schema_validation_batch_report.v1` artifact that summarizes every lintable JSON
artifact contract in a directory while preserving each nested
`schema_validation_report.v1` and listing skipped non-artifact JSON files with
their skip reason. `study_results/schema_validation_batch_report_v1.json`
persists that directory-level gate as a checked-in fixture.
Reports carry the validated contract, validation mode, pass/fail status, error
and warning counts, path/message issue rows, remediation rows for failing
inputs, schema-visible `model_limits`, and assumptions about executable versus
exported JSON Schema scope.
Remediation rows classify missing required fields, type mismatches, constant
mismatches, unsupported enum-like values, contract-inference failures,
unsupported contracts, and fallback semantic validation failures; artifacts
whose contract cannot be inferred still produce schema-valid validation reports
with `validated_contract: unknown`.
Executable validation treats validation-report error/warning/remediation counts,
validated schema versions, and batch file/artifact/skipped/error/warning totals
as integers, matching the exported JSON Schema instead of accepting
float-shaped summary counts; standalone validation reports also derive
error/warning/remediation counts and pass/fail status from their issue and
remediation rows so stale lint summaries fail validation, and their
`model_limits` must match the schema-validation model limits emitted by the
producer. Batch reports now carry the same schema-validation `model_limits` at
top level, and executable validation enforces them when present. The exported
`schema_validation_report.v1` and `schema_validation_batch_report.v1` JSON
Schemas constrain report-level, batch-level, and nested validation-report
`model_limits` arrays as the same exact string set, so schema-only import gates
can detect stale validation boundary metadata without invoking executable
validation.
The exported schema now types those issue rows with severity, path, and message
fields, and remediation rows with path, category, action, and source-message
fields for import-gate consumers. `OrbitalDynamics.validate_artifact/2`,
`OrbitalDynamics.schema_validation_report/2`,
`OrbitalDynamics.artifact_json_schema/1`, and
`OrbitalDynamics.artifact_json_schema_bundle/0` expose the same executable
validation and compatibility JSON Schema surfaces at the top-level API. Schemas
for contracts that declare nested contracts include those direct nested
definitions under `$defs`, so import-gate consumers can inspect the declared
row contracts without loading the full registry bundle.
Standalone schema-validation reports and batch reports can also be normalized
directly through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`, producing typed
`schema_validation_review` / `review_schema_validation` handoff rows that
expose `schema_validation_gate=artifact_contract_validation`, gate status, and
issue count while preserving the issue, remediation, full source validation
report, and batch entry path for adapter queues.
