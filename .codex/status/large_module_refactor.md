# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh candidate-selection context extraction.

Status:
Complete; publication pending.

Selected slice:
Extract the freshness and refresh-budget source-report validators behind their
existing public context functions.

Why this slice:
Freshness explains stale/unknown candidate eligibility and refresh budget
records the resulting kept/dropped candidate set. Together they form a cohesive
candidate-selection validation responsibility with focused replay/build tests.
Objective-gap demand validation remains out of scope.

Public facade to preserve:
`validate_freshness_context/4` and `validate_refresh_budget_context/4`, including
their callback-list guards, validation order, paths, messages, and all other
public signatures.

Extraction target:
`CandidateRefreshCandidateSelectionContracts`, with separate freshness and
refresh-budget entry points.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_candidate_selection_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
Both public `/4` facades delegate to a 63-line candidate-selection owner. The
complete freshness and refresh-budget flows moved, and the report-contract
facade fell from 504 to 463 lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- eight focused freshness/budget replay/build files plus candidate-refresh
  schema and resource-provenance contracts: 42 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 42 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published validation-safety-case extraction `f4789df9`; selected this slice in
`a9cecd54`.

Blocked:
No.
