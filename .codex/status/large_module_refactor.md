# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh validation-safety-case context extraction.

Status:
Complete; publication pending.

Selected slice:
Move the validation-safety-case source-report validator and its count-field
reduction into the existing validation-report owner, while wrapping the
callback-provided count-field lookup at the public facade boundary.

Why this slice:
The context is the remaining validation-report responsibility beside the newly
extracted schema-validation and model-acceptance flows. Its string-list import
and count reducer are otherwise exclusive to this flow. Resolving
`safety_case_count_fields` in the facade preserves callback injection without
leaking the callback bag into the internal owner. The lookup must remain
deferred until the original final validation step.

Public facade to preserve:
`validate_validation_safety_case_context/4`, including its callback-list guard,
callback lookup timing, validation order, paths, messages, and all other public
signatures.

Extraction target:
`CandidateRefreshValidationReportContracts.validate_safety_case/4`, accepting
a zero-arity count-field resolver invoked after the fixed safety-case fields.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_validation_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
The public `/4` facade delegates through a deferred zero-arity field resolver.
The safety-case body, reducer, and collection import moved into the existing
validation-report owner; the facade fell from 535 to 504 lines and the owner
grew from 84 to 121 lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- candidate-refresh resource-provenance and schema contracts: 11 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded review found no code issues; its resolver probe confirmed one deferred
  invocation and original early-failure ordering

Verification gaps:
- Full repository suite not run.

Last commit:
Published validation-report extraction `803671c3`; selected this slice in
`9998032f`.

Blocked:
No.
