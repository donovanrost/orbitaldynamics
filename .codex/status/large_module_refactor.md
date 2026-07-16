# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh validation-safety-case context extraction.

Status:
Selected; implementation pending.

Selected slice:
Move the validation-safety-case source-report validator and its count-field
reduction into the existing validation-report owner, while resolving the
callback-provided count-field list at the public facade boundary.

Why this slice:
The context is the remaining validation-report responsibility beside the newly
extracted schema-validation and model-acceptance flows. Its string-list import
and count reducer are otherwise exclusive to this flow. Resolving
`safety_case_count_fields` in the facade preserves callback injection without
leaking the callback bag into the internal owner.

Public facade to preserve:
`validate_validation_safety_case_context/4`, including its callback-list guard,
callback lookup timing, validation order, paths, messages, and all other public
signatures.

Likely extraction target:
`CandidateRefreshValidationReportContracts.validate_safety_case/4`, accepting
the resolved count-field list after the fixed safety-case fields.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_validation_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` context is a thin delegate that resolves the callback-provided
field list, the safety-case body and exclusive reducer/import move without
duplication, validation and callback behavior remain exact, and focused/broader
checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Validation-report context extraction published as `803671c3`: an 84-line owner
reduced the report-contract facade from 601 to 535 lines; 11 focused, 755
candidate-refresh, and 22 export tests passed; checked-in schemas and fingerprint
were unchanged; bounded review found no issues.

Blocked:
No.
