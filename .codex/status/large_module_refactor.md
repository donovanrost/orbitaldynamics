# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the seven contiguous lifecycle-state tests from reusable status/approval
transition helpers through lifecycle-state summary into one focused
`timeline_lifecycle_state_test.exs` module. Keep transition-decision and
transition-application tests in the original ledger.

Selection evidence:
- The selected seven tests are one contiguous lifecycle-state family covering
  transition construction, safe application, selected-integrity gating,
  status/approval state artifacts, combined lifecycle state, and summary
  aggregation.
- The family is self-contained: it uses only `Timeline` and `Schema`, with no
  private test helpers, setup, fixtures, or cross-test state.
- The next test begins the distinct reusable transition-decision/application
  family and remains in the original module.
- The current test ledger is 12,901 lines; the selected family spans about 1,337
  lines.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  schema validation, and all other test families remain outside the boundary.

Verification:
Pending: seven-test focused baseline, mechanical AST-preserving move, strict
compile, focused new/original/full Timeline tests, schema contracts,
structural/static checks, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline lifecycle-state summary assembly policy extraction, selected in
`65a3fa6a` and implemented in `8afb167b`.

Next candidate:
Continue matching large Timeline test families to the extracted production
boundaries, then return to production facade mapping.

Blocked:
No.
