# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export operational-timeline test split.

Status:
Complete and published.

Selected boundary:
Move both operational-timeline schema assertion clusters into one focused
export test. Preserve end-to-end coverage by invoking the Mix export task and
reading the generated bundle; leave adjacent timeline-diff, transition,
integrity, and Cadence assertions in the original test.

Selection evidence:
- The selected expressions use only the exported `schemas` map and
  `OrbitalDynamics.Timeline` capabilities/model limits.
- They cover schema presence, model/limits, command-authority fields, row
  required fields, count-map enums, operational-kind counts, orientation type,
  and timeline-identity pattern.
- The new test will retain Mix task invocation, captured IO, output cleanup, and
  task re-enablement, so assertions still prove serialized export behavior.
- The split should further reduce the current 8,578-line bundle-content ledger
  without moving its 14 helpers or weakening the selected assertions.
- Production code, public APIs, generated schema exports, other contract-family
  assertions, and helper ownership remain outside the boundary.

Verification:
- Selection published in `779f8c11`; implementation published in `5b1c6ac9`.
- Original bundle test baseline: 1 passed.
- Strict warnings-as-errors compile: 3,800 files compiled.
- Focused operational-timeline export test: 1 passed.
- Retained bundle-content test: 1 passed.
- Canonical AST comparison: retained bundle remainder and all 20 moved
  operational-timeline expressions equivalent in order.
- Static checks confirmed no operational-timeline assertions remain in the
  original, unchanged 14-helper set, no temporary checker, and clean
  formatting/diff.
- Independent review: clean, with no findings.
- Original export ledger is 8,450 lines; the focused operational-timeline
  module is 153 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export operational-timeline test split, selected in `779f8c11` and
implemented in `5b1c6ac9`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
