# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-refresh provenance test family split.

Status:
Completed and verified.

Selected boundary:
Split the 3,778-line candidate-refresh resource-provenance schema ledger into
four independently runnable families: base readiness/resource contracts;
station/contact/maneuver/policy reports; quality/timeline/resource feedback
reports; and timeline lifecycle/publication plus reservation evidence. Keep all
assertions and the checked-in artifact reader in the same focused module.

Selection evidence:
- The proposed restart points begin at self-contained `artifact_with_*`
  sections on lines 484, 1,498, and 2,627.
- Shared reason-count/schema variables from the base section have no uses after
  line 268; later schema contexts are reloaded within their own families.
- Each later family needs only a fresh copy of the same checked-in artifact,
  so no production behavior or assertion needs to move or weaken.

Implementation:
Selected in `54c572f8` and implemented in `eaa19f44`. Split the single
candidate-refresh provenance ledger into four tests at self-contained
source-report family boundaries. Each later family reloads the same checked-in
artifact; the quality/timeline/resource family also reloads the public
candidate-refresh schema it consumes. All original assertions remain in place.

Verification:
- The focused provenance module passed with warnings as errors: 4 tests.
- The full schema/validation gate passed with warnings as errors: 364 tests.
- Full checked-in schema export regeneration produced no diff.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format and `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema candidate-refresh provenance test family split, selected in `54c572f8`
and implemented in `eaa19f44`. The 3,778-line ledger now exposes four
independently runnable source-report contract families.

Next candidate:
Refresh the remaining schema-test inventory and select the next coherent family
boundary; production facades and the newly split provenance ledger need no
line-count-only churn.

Blocked:
No.
