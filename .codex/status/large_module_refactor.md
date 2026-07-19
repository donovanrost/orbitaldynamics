# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback resource override projection extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract resource margin and availability override projection, trust-value
projection, spacecraft identity resolution, nested resource evidence lookup,
conservative merge rules, and deterministic nested-map sorting into
`OrbitalDynamics.TimelineFeedback.ResourceFeedback`. Preserve all public
TimelineFeedback reconciliation and operational-feedback facades.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 2,472 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected helper families span lines 1,869-1,957 and 1,995-2,133 and
  jointly own resource margin/availability overrides and their shared
  normalization primitives.
- Operational-feedback construction and trust-boundary provenance are the only
  consumers of the five resource-feedback entry points.
- Target, downlink, maneuver, observation, and command feedback; reconciliation
  row construction; matching; normalization; public clauses; and artifact
  contracts remain outside this boundary.
- Existing exclusion filtering, source precedence, spacecraft/scenario
  identity fallback, numeric/boolean normalization, min/max margin merging,
  conservative availability merging, degraded-mode preference, string-list
  deduplication/sorting, and empty-map behavior must remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness adapter-boundary evidence extraction, selected in
`f917e600` and implemented in `967b7ade`.
`operational_readiness.ex` moved from 2,500 to 2,385 lines; the dedicated
adapter-boundary evidence owner is 121 lines.

Next candidate:
Complete and verify the selected TimelineFeedback resource override projection
extraction.

Blocked:
No.
