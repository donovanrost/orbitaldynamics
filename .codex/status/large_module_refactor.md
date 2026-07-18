# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline dependency-impact summary policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move dependency-impact source identity derivation, row-policy orchestration,
scope/row ID aggregation, and the summary artifact map from the Timeline facade
into one `DependencyImpactSummaryPolicy` module. Keep public guards, diff
generation, activity normalization, schema-contract ownership, and model-limit
ownership in the facade.

Selection evidence:
- The remaining three dependency-impact private helpers are used only by
  `dependency_impact_summary/3`.
- The extracted row policy provides the lower-level source/replacement row
  boundary; summary assembly is now a cohesive next layer.
- The facade can supply its existing schema contract, model limits, and
  `sorted_uniq/1` behavior, preserving ownership and deterministic ordering.
- Focused tests cover changed/removed activity dependencies, timeline-ID
  dependencies, combined exclusivity, clear status, facade parity, persisted
  fixtures, and schema validation.
- Timeline is 5,227 lines; the selected summary body and helpers span about 100
  additional lines of dependency-impact responsibility.
- Public Timeline APIs, input validation and normalization, capability values,
  report/schema shapes, field ordering, generated exports, and other timeline
  responsibilities remain outside the boundary.

Verification:
Pending: focused baselines, mechanical summary-policy extraction, strict
compile, focused and full Timeline tests, schema contracts, structural/static
checks, and independent review.

Behavior/schema changes:
None intended. Dependency-impact row order, ID ordering, summary fields,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline dependency-impact row policy extraction, selected in `bf4f2e94` and
implemented in `ece31812`.

Next candidate:
Continue remapping the reduced Timeline facade after the dependency-impact
summary boundary is owned.

Blocked:
No.
