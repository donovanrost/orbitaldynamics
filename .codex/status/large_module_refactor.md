# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline-transition test family split.

Status:
Complete and published in `8621886e`.

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
- The pre-move focused baseline passed all four selected tests from selection
  commit `55413ac8`.
- Strict test compilation passed with warnings as errors across 3,804 files.
- The new focused module passed 4 tests; the reduced original passed 92 tests;
  the combined CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An exact AST comparison against `55413ac8` proved that the original module is
  exactly its former body minus the four selected tests, the focused module owns
  those exact test ASTs, and its four fixture helpers are exact copies.
- Formatting, tracked and new-file diff checks, exact static test/helper counts,
  temporary-checker absence, and the resource-flow/policy-escalation seam passed.
- Bounded local review found no assertion, fixture-value, production, public API,
  schema, deterministic-output, or supported-source-registry change.
- The original ledger fell from 15,292 to 14,831 lines; the focused module is
  581 lines.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport timeline-transition test family split, selected in `55413ac8` and
implemented in `8621886e`.

Next candidate:
Refresh the remaining CadenceImport families and production facade map, then
select one cohesive boundary with independent fixtures or a small exact helper
copy surface.

Blocked:
No.
