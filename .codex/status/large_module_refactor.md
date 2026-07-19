# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline dependency-impact summary policy extraction.

Status:
Completed and published.

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
- Focused baseline passed 2 dependency-impact summary tests.
- Strict warnings-as-errors compile passed 3,802 modules; the post-interruption
  incremental warnings-as-errors compile also passed.
- Focused dependency-impact summary tests passed 2 tests.
- Full Timeline suite passed 127 tests.
- Four Timeline schema-contract suites passed 36 tests.
- AST conservation proved the summary assembly and three selected helpers moved
  exactly after normalizing only callback/configuration threading.
- Static checks confirmed the three helpers left Timeline, the facade has one
  summary-policy call, public def count remains 101, formatting/diff/new-file
  checks pass, and no temporary checker remains.
- Compile-connected xref remained narrow: Timeline has only the pre-existing
  compile edge to `CandidateRejectionStationPolicy`.
- The prior review sidecar was unavailable after interruption; bounded local
  review found no correctness or maintainability issues and confirmed
  source-then-replacement ordering, schema/model ownership, output fields, and
  deterministic ordering are unchanged.
- Timeline decreased from 5,227 to 5,144 lines; the extracted policy is 108
  lines.

Behavior/schema changes:
None intended. Dependency-impact row order, ID ordering, summary fields,
capabilities, and schema exports should remain byte-for-byte stable.

Last completed slice:
Timeline dependency-impact summary policy extraction, selected in `59e8b1bf`
and implemented in `8b53743d`.

Next candidate:
Continue remapping the reduced Timeline facade after the dependency-impact
summary boundary is owned.

Blocked:
No.
