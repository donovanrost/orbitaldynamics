# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state summary assembly policy extraction.

Status:
Completed and published.

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
- Focused baseline passed 1 lifecycle-state summary test.
- Strict warnings-as-errors compile passed 3,804 modules.
- Focused lifecycle-state summary test passed 1 test.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved the full summary artifact assembly and three selected
  metric wrappers moved exactly after normalizing only metadata/callback
  threading.
- Static checks confirmed all three metrics helpers left Timeline, the facade has
  one summary-policy call, public def count remains 101,
  formatting/diff/new-file checks pass, and no temporary checker remains.
- Compile-connected xref remained narrow: Timeline has only the pre-existing
  compile edge to `CandidateRejectionStationPolicy`.
- Bounded local review found no correctness or maintainability issues and
  confirmed derived counts, review rows, routing ID maps, assumptions, map-key
  ordering, and deterministic ID ordering are unchanged.
- Timeline decreased from 5,010 to 4,923 lines; the extracted policy is 160
  lines.

Behavior/schema changes:
None intended. Derived counts, routing ID sets, review rows, map ordering,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline lifecycle-state summary assembly policy extraction, selected in
`65a3fa6a` and implemented in `8afb167b`.

Next candidate:
Continue remapping the reduced Timeline facade after lifecycle-state summary
assembly is policy-owned.

Blocked:
No.
