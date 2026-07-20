# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review export test split.

Status:
Selected; implementation pending.

Selected boundary:
Move the 717-line nested operator-review row schema export test from the
1,814-line mixed contract module into a focused sibling with a local JSON
reader. Keep the exhaustive checked-in operator-review package fixture test in
the original module.

Selection evidence:
- The export test ends before the checked-in package test begins at line 723.
- Both tests depend only on the public `Schema` facade and the generic five-line
  JSON reader.
- The two tests cover distinct responsibilities: nested schema shape versus
  executable validation and deterministic fixture content.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema contact-feedback export test split, selected in `9ca6df2a` and
implemented in `0ae4ae5c`. The 1,853-line mixed module became balanced 907-line
fixture/behavior and 957-line nested-export modules.

Next candidate:
Implement and verify the selected operator-review schema export test split.

Blocked:
No.
