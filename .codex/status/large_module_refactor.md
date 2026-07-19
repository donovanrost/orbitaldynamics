# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state summary row policy extraction.

Status:
Selected; implementation has not started.

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
Pending: focused baseline, mechanical row-policy extraction, strict compile,
focused and full Timeline tests, schema contracts, structural/static checks, and
bounded review.

Behavior/schema changes:
None intended. Lifecycle row selection, review routing, ID ordering, summary
fields, capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline dependency-impact summary policy extraction, selected in `59e8b1bf`
and implemented in `8b53743d`.

Next candidate:
Continue remapping the reduced Timeline facade after lifecycle summary row
ownership is isolated.

Blocked:
No.
