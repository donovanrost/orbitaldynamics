# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation approval-policy ownership extraction.

Status:
Completed and pushed in `0593a3ef`.

Selected boundary:
Extract allocation policy-boundary detection, approval decisions,
requirements, command/health-check classification, and policy context
projection into
`OrbitalDynamics.Communications.ContactAllocation.ApprovalPolicy`. Preserve
the existing allocation/report facade.

Selection evidence:
- Live re-ranking places `communications/contact_allocation.ex` at 3,984 lines,
  ahead of TimelineFeedback and Manifest and behind the three larger
  orchestration-heavy facades.
- The selected policy projection has one facade entry point and forms one
  approval-review responsibility.
- Contact normalization, allocation and packing decisions, summary
  aggregation, provider counteroffers, and returned allocation projection
  remain with their existing owners.
- The facade passes its command-direction policy explicitly; no configuration
  is duplicated.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,903
  files.
- Focused ContactAllocation coverage passed: 70 tests.
- Adjacent operator-review, schema-contract, provider-reservation-contract,
  and validation-fixture coverage passed: 25 tests.
- Exact public old/new comparison against selection commit `af08b116` passed
  for eight policy-enabled allocations including command and health-check rows.
- `mix xref callers` reports only the ContactAllocation facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm policy projection lives in ApprovalPolicy
  while allocation, packing, and summary responsibilities remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation approval-policy ownership extraction, selected in
`af08b116` and implemented in `0593a3ef`.
`communications/contact_allocation.ex` moved from 3,984 to 3,782 lines; the
dedicated owner is 218 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
