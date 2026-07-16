# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh validation-report context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the schema-validation and model-acceptance source-report validators,
including the model-acceptance count-map helper, behind their existing public
context functions.

Why this slice:
These adjacent contexts form one cohesive validation-report responsibility,
share the same primitive count/map validation vocabulary, and have direct
candidate-refresh provenance coverage. The model-acceptance helper is exclusive
to this flow. The callback-coupled validation-safety-case context remains out of
scope for this slice.

Public facade to preserve:
`validate_schema_validation_context/4` and
`validate_model_acceptance_context/4`, including callback-list guards, argument
order, validation order, paths, messages, and all other public signatures.

Likely extraction target:
`CandidateRefreshValidationReportContracts`, with separate schema-validation
and model-acceptance entry points and the private model-acceptance count-map
helper.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_validation_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
Both public `/4` context functions are thin delegates, their callback guards are
unchanged, the exclusive count-map helper moves without duplication, validation
order/paths/errors remain exact, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Contact-intent context extraction published as `36d9f0b4`: a 96-line owner
reduced the report-contract facade from 665 to 601 lines; 36 focused, 755
candidate-refresh, and 22 export tests passed; checked-in schema artifacts and
fingerprint were unchanged; bounded review found no issues.

Blocked:
No.
