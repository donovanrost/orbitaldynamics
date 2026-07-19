# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity relay data-path summary extraction.

Status:
Completed and pushed in `2acd5177`.

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
- Strict test-environment compile passed with warnings as errors across 3,928
  files.
- Focused LinkCapacity coverage passed: 44 tests.
- Adjacent relay replay, operator-review, schema-contract, and validation
  fixture coverage passed: 22 tests.
- Exact public old/new comparison against selection commit `b3395bce` passed
  for five route sets across list input, idempotent string-key summary, and
  atom-key summary paths, plus relay capability metadata and four invalid
  inputs.
- `mix xref callers` reports only the LinkCapacity facade as a runtime caller
  of the extracted relay data-path owner.
- Static ownership checks confirm relay contracts/statuses/model limits, route
  identity, chain/custody/latency/risk normalization, aggregate routing maps,
  and artifact assembly live in the dedicated owner while fixed-rate capacity
  responsibilities remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
LinkCapacity relay data-path summary extraction, selected in `b3395bce` and
implemented in `2acd5177`.
`link_capacity.ex` moved from 3,520 to 3,113 lines; the dedicated relay
data-path owner is 506 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
