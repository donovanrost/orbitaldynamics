# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema export validation-family test split.

Status:
Selected; implementation has not started.

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
Pending: focused baseline, mechanical assertion move, strict compile,
focused/original test files, structural/static checks, and independent review.

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
