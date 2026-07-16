# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh validation-report context extraction.

Status:
Complete; publication pending.

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

Extraction target:
`CandidateRefreshValidationReportContracts`, with separate schema-validation
and model-acceptance entry points and the private model-acceptance count-map
helper.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_validation_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
Both public `/4` facades now delegate to an 84-line validation-report owner.
The exclusive model-acceptance count-map helper moved with its flow, and the
report-contract facade fell from 601 to 535 lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- candidate-refresh resource-provenance and schema contracts: 11 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 11 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published contact-intent extraction `36d9f0b4`; selected this slice in
`610d5b2b`.

Blocked:
No.
