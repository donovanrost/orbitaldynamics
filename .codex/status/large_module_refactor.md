# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection activity evidence validation extraction.

Status:
Completed and pushed.

Selected boundary:
Extract completed-fraction, station-capacity, latency, resource-quantity, and
nested actual-data-volume evidence validation into
`OrbitalDynamics.ResourceProjection.ActivityInputValidation`. Centralize the
advertised actual-data-volume evidence paths with that owner. Preserve all
public ResourceProjection report and flow-summary facades.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 2,418
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 822-1,042 and exclusively owns four
  validation decisions and their evidence discovery.
- Activity-input normalization is the only consumer of the validation entry
  points; actual-volume projection also consumes the shared evidence paths.
- Activity identity/type normalization, source-window normalization, resource
  arithmetic, flow construction, approval policy, public clauses, and artifact
  contracts remain outside this boundary.
- Existing top-level/metadata/model/source precedence, recursive capacity
  evidence discovery, first-error ordering, unit-interval/percent bounds,
  non-negative latency/resource guards, nil handling, numeric-string parsing,
  path presence semantics, exact reason strings, and path metadata must remain
  unchanged.

Implementation:
- Selection was recorded and pushed in `d39bd372`.
- Implementation was committed and pushed in `66c5aca8`.
- `resource_projection.ex` moved from 2,418 to 2,197 lines.
- `OrbitalDynamics.ResourceProjection.ActivityInputValidation` is a 253-line
  owner reached through four private facade delegates plus the shared
  actual-volume path contract.

Verification:
- Strict warning-clean compilation passed across 3,970 files.
- The focused ResourceProjection file and five adjacent operator-review,
  Cadence-import, schema, campaign-strategy, and replay consumers passed
  together: 146 tests.
- Exact old/new public parity passed for 14 validation and capability cases
  covering valid numeric strings; completed-fraction, nested capacity,
  allocation/overlap, latency, resource-quantity, and actual-volume errors;
  nil behavior; first-error ordering; and path metadata.
- `mix xref callers` reports only the ResourceProjection facade.
- The removed validation/evidence-walking helpers and facade-owned actual
  volume path attribute are absent apart from thin delegates, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection activity evidence validation extraction, selected in
`d39bd372` and implemented in `66c5aca8`.
`resource_projection.ex` moved from 2,418 to 2,197 lines; the dedicated
activity-input validation owner is 253 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
