# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application test family split.

Status:
Completed and published.

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
- Focused baseline passed the eight selected tests.
- Strict warnings-as-errors compile passed 3,804 modules.
- The first focused run exposed the shared `read_json!/1` dependency; the
  corrected boundary was published in `c8a29923`.
- Focused transition-application test module passed 8 tests.
- Reduced original Timeline test module passed 112 tests.
- Combined original, lifecycle-state, and transition-application modules passed
  127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved all eight test bodies and the family-specific helper
  moved exactly; the shared decoder remains unchanged in the original and is
  duplicated unchanged in the focused module.
- Static checks confirmed the original and focused modules each have two private
  helpers, the moved helper is absent from the original, test counts are exact,
  formatting/diff/new-file checks pass, and no temporary extraction/checker
  remains.
- Bounded local review found no correctness or maintainability issues and
  confirmed the original family boundary now runs directly from source-window
  coverage into lifecycle-preservation coverage.
- The original test ledger decreased from 11,564 to 10,234 lines; the focused
  transition-application module is 1,341 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline transition-application test family split, selected in `97170e3d`,
corrected in `c8a29923`, and implemented in `04a19d66`.

Next candidate:
Continue matching Timeline test families to extracted production boundaries,
then return to production facade mapping.

Blocked:
No.
