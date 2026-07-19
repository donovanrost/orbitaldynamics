# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity relay data-path summary extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract relay/store-and-forward route identity, relay-chain, custody, latency,
risk normalization, aggregate maps, and artifact assembly into
`OrbitalDynamics.Communications.LinkCapacity.RelayDataPath`.
Preserve the existing LinkCapacity public API facade.

Selection evidence:
- Live re-ranking places `link_capacity.ex` at 3,520 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of StationCalendar,
  TimelineFeedback, ResourceProjection, Manifest, ContactAllocation,
  RecommendationRiskContext, and OperationalReadiness.
- The selected family owns one independent public artifact responsibility:
  describing direct and relayed spacecraft data paths without scheduling or
  provider mutation.
- Fixed-rate contact capacity, selected/actual throughput reconciliation,
  station-calendar evidence, downlink requirements, approval policy, and link
  capacity report/summary assembly remain outside this boundary.
- Existing route-id generation, alias precedence, custody/latency/risk status
  rules, reason derivation, aggregation, error behavior, model limits, and
  deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest candidate-refresh run-input source extraction, selected in `a29d7dd7`
and implemented in `74cc1a1d`.
`manifest.ex` moved from 3,530 to 3,357 lines; the dedicated run-input-source
owner is 185 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
