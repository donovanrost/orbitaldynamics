# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state summary assembly policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move lifecycle-state review-row selection, derived counts, routing ID sets, and
artifact map assembly into one `LifecycleStateSummaryPolicy`. Keep input
grouping, timeline pairing, row-policy calls, public guards, and source/schema/
model-limit ownership in the facade.

Selection evidence:
- Input grouping and row classification now have explicit policy owners, leaving
  one cohesive aggregation/artifact block in the facade.
- The new policy can call `CountSummaryPolicy`, `IdentityGroupingPolicy`, and
  `LifecycleStateSummaryMetricsPolicy` directly; it needs only the existing
  deterministic sorted-ID callback from the facade.
- The three lifecycle summary metrics wrappers are used only by the selected
  artifact block and can be removed as redundant facade plumbing.
- One focused high-signal test covers all derived counts, review routing maps,
  unique/duplicate/invalid rows, deterministic ID sets, facade parity, stale
  contract rejection, and invalid argument behavior.
- Timeline is 5,010 lines; the selected artifact block and wrappers span about
  120 lines.
- Public Timeline APIs, input normalization/grouping, timeline pairing, row
  classification, source/schema/model ownership, capability values, generated
  exports, and other lifecycle responsibilities remain outside the boundary.

Verification:
Pending: focused baseline, mechanical summary-policy extraction, strict compile,
focused and full Timeline tests, schema contracts, structural/static checks, and
bounded review.

Behavior/schema changes:
None intended. Derived counts, routing ID sets, review rows, map ordering,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline lifecycle-state input grouping policy completion, selected in
`aa1d7c62` and implemented in `9af8e6e1`.

Next candidate:
Continue remapping the reduced Timeline facade after lifecycle-state summary
assembly is policy-owned.

Blocked:
No.
