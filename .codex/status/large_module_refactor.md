# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-refresh provenance test family split.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema timeline change-summary contract test split, selected in `28d774ca` and
implemented in `2599c015`. The 2,477-line timeline ledger became balanced
1,154-line lifecycle and 1,334-line change-observation modules.

Next candidate:
Implement and verify the selected candidate-refresh provenance test-family
split.

Blocked:
No.
