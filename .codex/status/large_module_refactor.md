# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state summary row policy extraction.

Status:
Completed and published.

Selected boundary:
Move lifecycle-state row classification, duplicate-identity review-row
construction, and invalid-input review-row construction from the Timeline
facade into one `LifecycleStateSummaryRowPolicy` module. Keep input grouping,
summary aggregation, public guards, and artifact assembly in the facade.

Selection evidence:
- The three selected helpers are called only while mapping paired lifecycle
  summary rows.
- Duplicate counts and activity-ID derivation already belong to
  `LifecycleStateSummaryMetricsPolicy`; the row policy can call that module
  directly while receiving the facade's existing sorted-ID behavior.
- Unique-pair rows continue to reuse the public `activity_lifecycle_state/2`
  semantics through a facade-supplied callback.
- One focused high-signal test covers unique record/preserve/review rows,
  duplicate timeline identities, invalid inputs, deterministic ID ordering,
  facade parity, schema validation, and invalid argument behavior.
- Timeline is 5,144 lines; the selected row cluster spans about 90 lines.
- Public Timeline APIs, input grouping, summary aggregation, schema/model
  ownership, capability values, generated exports, and other lifecycle
  responsibilities remain outside the boundary.

Verification:
- Focused baseline passed 1 lifecycle-state summary test.
- Strict warnings-as-errors compile passed 3,803 modules.
- Focused lifecycle-state summary test passed 1 test.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved the three row functions and two redundant metrics
  wrappers moved exactly after normalizing only callback threading and direct
  policy delegation.
- Static checks confirmed all five helpers left Timeline, the facade has one row
  policy call, public def count remains 101, formatting/diff/new-file checks
  pass, and no temporary checker remains.
- Compile-connected xref remained narrow: Timeline has only the pre-existing
  compile edge to `CandidateRejectionStationPolicy`.
- Bounded local review found no correctness or maintainability issues and
  confirmed duplicate/invalid precedence, unique-pair lifecycle semantics,
  review routing, field ordering, and deterministic ID ordering are unchanged.
- Timeline decreased from 5,144 to 5,046 lines; the extracted policy is 112
  lines.

Behavior/schema changes:
None intended. Lifecycle row selection, review routing, ID ordering, summary
fields, capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline lifecycle-state summary row policy extraction, selected in `c813f233`
and implemented in `6fa5b2bd`.

Next candidate:
Continue remapping the reduced Timeline facade after lifecycle summary row
ownership is isolated.

Blocked:
No.
