# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline change-summary contract test split.

Status:
Completed and verified.

Selected boundary:
Move the publication, dependency-impact, integrity, and diff schema/fixture
tests from the 2,477-line timeline-summary contract module into a focused
timeline change-summary sibling. Keep preservation, transition-application, and
activity-precondition families plus their assumption helpers in the original.

Selection evidence:
- The first eight tests end before the preservation family begins at line
  1,329.
- Those four change-observation families depend only on `Schema` and the
  five-line JSON fixture reader.
- The remaining nine tests form lifecycle preservation/transition/precondition
  contracts and own all three specialized assumption helpers.

Implementation:
Selected in `28d774ca` and implemented in `2599c015`. Moved eight
publication/dependency-impact/integrity/diff schema and fixture tests into
`TimelineChangeSummaryContractsTest` with a local JSON reader. The original
timeline-summary module moved from 2,477 to 1,154 lines; the new focused module
is 1,334 lines.

Verification:
- Both focused timeline schema modules passed with warnings as errors: 17 tests.
- The full schema/validation gate passed with warnings as errors: 361 tests.
- Full checked-in schema export regeneration produced no diff.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format checks, new-file whitespace checks, and
  `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema timeline change-summary contract test split, selected in `28d774ca` and
implemented in `2599c015`. The 2,477-line timeline ledger became balanced
1,154-line lifecycle and 1,334-line change-observation modules.

Next candidate:
Refresh the named-hotspot test inventory and select the next largest coherent
family boundary; avoid further splitting already focused modules solely by line
count.

Blocked:
No.
