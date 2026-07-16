# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh contact-intent context extraction.

Status:
Complete; publication pending.

Selected slice:
Extract the complete contact-intent source-report validator and its exclusive
stable-ID map helper behind the existing public context function, while reusing
the already extracted direction-routing owner.

Why this slice:
The context and stable-ID helper form one cohesive capacity/routing validation
responsibility with six focused replay/build suites. The routing module remains
shared with the public `/5` routing facade.

Public facade to preserve:
`validate_contact_intent_context/4` and the existing
`validate_contact_intent_direction_routing/5`, including their callback-list
guards, plus all other public signatures.

Extraction target:
`CandidateRefreshContactIntentContracts.validate/3`, owning the full context
flow and stable-ID map helper while delegating routing to
`CandidateRefreshContactIntentRoutingContracts`.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_contact_intent_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
The public context `/4` facade now delegates to a 96-line contact-intent owner;
the public routing `/5` facade is unchanged. The exclusive stable-ID helper
moved with the context, and the report-contract facade fell from 665 to 601
lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- six focused contact-intent replay/build suites plus candidate-refresh schema
  and resource-provenance contracts: 36 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 36 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published quality-gate extraction `b048b7bf`.

Blocked:
No.
