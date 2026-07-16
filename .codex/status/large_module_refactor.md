# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh objective-gap context extraction.

Status:
Complete; publication pending.

Selected slice:
Extract the complete objective-gap source-report validator behind its existing
public context function.

Why this slice:
The four gap counters and seven demand/routing count maps form one self-contained
objective-demand validation responsibility. The flow has a dedicated replay
suite and direct schema error-path coverage, with no callback or shared private
helper coupling.

Public facade to preserve:
`validate_objective_gap_context/4`, including its callback-list guard, argument
order, validation order, paths, messages, and all other public signatures.

Extraction target:
`CandidateRefreshObjectiveGapContracts.validate/3`.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_objective_gap_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
The public `/4` facade delegates to a 41-line objective-gap owner. The complete
counter/map flow moved, and the report-contract facade fell from 463 to 436
lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- objective-gap replay plus candidate-refresh schema/provenance contracts:
  22 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 22 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published candidate-selection extraction `3270171b`; selected this slice in
`d869971b`.

Blocked:
No.
