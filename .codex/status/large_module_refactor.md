# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export validation-family test split.

Status:
Complete and published.

Selected boundary:
Move the final model-acceptance, validation-safety-case, and validation
reference-fixture schema assertions into a focused validation-family export
test. Preserve end-to-end coverage by invoking the Mix export task and reading
the generated bundle in the new test.

Selection evidence:
- The selected tail block uses only the exported `schemas` map and
  `OrbitalDynamics.Validation.capabilities().known_limits`.
- The new test will retain Mix task invocation, captured IO, output cleanup, and
  task re-enablement, so assertions still prove serialized export behavior.
- The split should further reduce the current 8,671-line bundle-content ledger
  without moving its 14 helpers or weakening the selected assertions.
- Production code, public APIs, generated schema exports, other contract-family
  assertions, and helper ownership remain outside the boundary.

Verification:
- Selection published in `832e0d04`; implementation published in `08b23d2c`.
- Original bundle test baseline: 1 passed.
- Strict warnings-as-errors compile: 3,800 files compiled.
- Focused validation-family export test: 1 passed.
- Retained bundle-content test: 1 passed.
- Canonical AST comparison: retained bundle prefix and moved validation suffix
  equivalent; independent review accounted for all 937 original expressions.
- Static checks confirmed all three validation contracts moved, unchanged
  14-helper set, no temporary checker, and clean formatting/diff.
- Independent review: clean, with no findings.
- Original export ledger is 8,578 lines; the focused validation module is 117
  lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export validation-family test split, selected in `832e0d04` and
implemented in `08b23d2c`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
