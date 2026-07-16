# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh candidate-rejection context extraction.

Status:
Complete; publication pending.

Selected slice:
Move the candidate-rejection source-report validator into the existing
candidate-selection owner behind its public context function.

Why this slice:
Candidate rejection is a candidate-selection outcome beside freshness and
refresh budget. Its two count maps are the final family-specific body and sole
remaining caller of the facade's private direct count-map helper, with two
focused replay suites and direct provenance error-path coverage.

Public facade to preserve:
`validate_candidate_rejection_context/4`, including its callback-list guard,
argument order, validation order, paths, messages, and all other public APIs.

Extraction target:
`CandidateRefreshCandidateSelectionContracts.validate_candidate_rejection/3`.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_candidate_selection_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
The public `/4` facade delegates to a 12-line entry point in the existing
candidate-selection owner. Both maps moved and the facade's final family-
specific private reducer was removed; the facade fell from 337 to 332 lines
without schema-export changes.

Verification:
- compile with warnings as errors passed
- two candidate-rejection files plus candidate-refresh schema and resource-
  provenance contracts: 24 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 24 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published communications-pressure extraction `923f946e`; selected this slice in
`dea80373`.

Blocked:
No.
