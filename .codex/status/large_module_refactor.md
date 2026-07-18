# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export CLI test-ledger split.

Status:
Complete and published.

Selected boundary:
Move the three Mix task CLI behavior tests for single-contract export, missing
required flags, and all-contract directory export into a dedicated test module.
Keep the giant schema-bundle content contract test and all of its local
model-limit helpers together in the original file. Give the all-contract
directory test a 120-second per-test timeout because standalone cold execution
can exceed ExUnit's 60-second default.

Selection evidence:
- The three tests share only Mix task invocation, captured IO, filesystem
  cleanup, and task re-enablement.
- The bundle-content test owns all schema-family assertions and every local
  helper, so it can remain unchanged.
- The split should reduce the current 8,764-line export test ledger without
  duplicating fixtures or weakening assertions.
- Initial standalone verification showed the all-contract directory export can
  exceed 60 seconds without the former bundle-test warmup; the assertion body
  remains unchanged and only that test receives the larger timeout.
- Production code, public APIs, generated schema exports, contract behavior,
  and the bundle-content assertion body remain outside the boundary.

Verification:
- Selection published in `d5bb3d07`; corrected timeout boundary published in
  `52c6ea2e`; implementation published in `03b4d2ec`.
- Focused baseline: 3 passed.
- Strict warnings-as-errors compile: 3,800 files compiled.
- Split CLI test module: 3 passed.
- Original bundle-content test module: 1 passed.
- Canonical AST comparison: all three moved test bodies equivalent; independent
  review also confirmed the retained bundle test is equivalent.
- Static checks confirmed exactly three unique moved test names, one retained
  bundle test, unchanged 14-helper set, no temporary checker, and clean
  formatting/diff.
- Independent review: clean, with no findings.
- Original export ledger is 8,671 lines; the focused CLI module is 101 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Schema export CLI test-ledger split, selected in `d5bb3d07`, corrected in
`52c6ea2e`, and implemented in `03b4d2ec`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
