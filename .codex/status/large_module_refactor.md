# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export CLI test-ledger split.

Status:
Selected; implementation has not started.

Selected boundary:
Move the three Mix task CLI behavior tests for single-contract export, missing
required flags, and all-contract directory export into a dedicated test module.
Keep the giant schema-bundle content contract test and all of its local
model-limit helpers together in the original file.

Selection evidence:
- The three tests share only Mix task invocation, captured IO, filesystem
  cleanup, and task re-enablement.
- The bundle-content test owns all schema-family assertions and every local
  helper, so it can remain unchanged.
- The split should reduce the current 8,764-line export test ledger without
  duplicating fixtures or weakening assertions.
- Production code, public APIs, generated schema exports, contract behavior,
  and the bundle-content assertion body remain outside the boundary.

Verification:
Pending: focused baseline, mechanical move, strict compile, focused/original
test files, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity scheduling-coordinate context extraction, selected in
`b5dbb381`, corrected in `c5eafdc1`, and implemented in `e1e22500`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
