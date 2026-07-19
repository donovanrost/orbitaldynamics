# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline-transition test family split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the four contiguous timeline transition/diff import tests into one focused
`cadence_import_timeline_transition_test.exs` module:
- timeline transition-application report import rows;
- transition-application summary import rows;
- timeline-diff summary import rows;
- stale nested transition-application evidence rejection.

Duplicate the four pure timeline summary/pair fixture helpers in the focused
module while retaining them in the original module because the original
supported-source fixture registry also calls both summary helpers. Keep the
preceding resource-projection flow validation test and following policy
escalation family in the original ledger.

Selection evidence:
- `cadence_import_test.exs` is the repository's largest source file at 15,292
  lines and contains 96 top-level tests.
- The selected contiguous family spans lines 8,846 through 9,306 and exercises
  one import responsibility across report, summary, facade, atom-key, validation,
  and stale nested-evidence paths.
- The four selected tests use only `CadenceImport`, `Schema`, `Timeline`, and
  `OrbitalDynamics`; they have no setup, external fixtures, or cross-test state.
- The required fixture helpers are pure data builders. Retaining the originals
  and copying exact AST-equivalent helpers into the new module avoids changing
  the supported-source fixture registry during this ownership-only split.
- Production code, public APIs, assertions, edge cases, assertion ordering,
  fixture values, schema validation, and all other test families remain outside
  the boundary.

Verification:
Pending: four-test focused baseline, mechanical AST-preserving move, exact
helper-copy proof, strict compile, focused new/original/combined CadenceImport
tests, relevant schema contracts, structural/static checks, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
Timeline candidate-rejection test family split, selected in `96f62b40` and
implemented in `39e58a20`.

Next candidate:
Continue responsibility-focused reduction of the CadenceImport ledger or return
to production facade mapping after this complete timeline import family is
isolated.

Blocked:
No.
