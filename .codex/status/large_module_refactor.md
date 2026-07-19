# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline candidate-rejection test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the three contiguous candidate-rejection tests into one focused
`timeline_candidate_rejection_test.exs` module. Keep the preceding public-facade
smoke test and following timeline-diff family in the original ledger.

Selection evidence:
- The selected tests cover declared/derived rejection evidence plus nested
  station-calendar capacity and availability derivation as one complete family.
- The family is self-contained: it uses only `Timeline` and `Schema`, with no
  private helpers, setup, fixture files, or cross-test state.
- The preceding test is a general facade smoke test; the following test begins
  the distinct timeline-diff report family.
- The current original test ledger is 10,234 lines; the selected family spans
  about 253 lines.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  schema validation, and all other test families remain outside the boundary.

Verification:
Pending: three-test focused baseline, mechanical AST-preserving move, strict
compile, focused new/original/combined Timeline tests, schema contracts,
structural/static checks, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline transition-application test family split, selected in `97170e3d`,
corrected in `c8a29923`, and implemented in `04a19d66`.

Next candidate:
Return to production facade mapping or pivot to the larger CadenceImport ledger
after this complete small family is isolated.

Blocked:
No.
