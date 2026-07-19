# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback resource override projection extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `f4bb05b5`.
- Implementation was committed and pushed in `42cfbee0`.
- `timeline_feedback.ex` moved from 2,472 to 2,267 lines.
- `OrbitalDynamics.TimelineFeedback.ResourceFeedback` is a 232-line owner
  reached through five private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,966 files.
- The focused TimelineFeedback file and six adjacent campaign-strategy,
  CandidateRefresh build, replay, and Cadence-import consumers passed
  together: 104 tests.
- Exact old/new public parity passed for 10 operational-feedback cases covering
  direct and nested source precedence, conservative margin min/max merging,
  degraded availability merging, list normalization, spacecraft/scenario and
  nested identity fallback, excluded and invalid rows, atom-keyed input, empty
  input, and public-error behavior.
- `mix xref callers` reports only the TimelineFeedback facade.
- The removed resource projection helpers are absent from the facade apart
  from thin delegates, formatting and `git diff --check` passed, and the final
  diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback resource override projection extraction, selected in
`f4bb05b5` and implemented in `42cfbee0`.
`timeline_feedback.ex` moved from 2,472 to 2,267 lines; the dedicated resource
feedback owner is 232 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
