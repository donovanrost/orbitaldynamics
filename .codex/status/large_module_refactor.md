# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the eight contiguous transition-decision/application tests and their
family-specific stale-selected-activity validation helper into one focused
`timeline_transition_application_test.exs` module. Retain the shared pure
`read_json!/1` helper in the original and duplicate it in the focused module;
keep lifecycle-preservation and candidate-rejection tests in the original.

Selection evidence:
- The selected eight tests form one contiguous family from reusable transition
  decisions through application reports, summaries, selected-activity
  extraction/rechecks, and exclusivity handoff.
- The stale-selected-activity helper has exactly three consumers, all inside this
  family, and moves with them.
- `read_json!/1` has one selected fixture consumer and two original-ledger
  consumers; duplicating this four-line pure decoder keeps fixture setup local
  without coupling the focused module back to the original.
- The family needs only `Timeline`, `Schema`, `OperatorReview`, and
  `CadenceImport`; it has no setup, fixture files, or cross-test state.
- The next test begins the distinct lifecycle-preservation family and remains in
  the original module.
- The current test ledger is 11,564 lines; the selected tests plus helper span
  about 1,330 lines.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  schema validation, and all other test families remain outside the boundary.

Verification:
Pending: eight-test focused baseline, mechanical AST-preserving test/helper
move, strict compile, focused new/original/combined Timeline tests, schema
contracts, structural/static checks, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline lifecycle-state test family split, selected in `274208f4` and
implemented in `047b6b90`.

Next candidate:
Continue matching Timeline test families to extracted production boundaries,
then return to production facade mapping.

Blocked:
No.
