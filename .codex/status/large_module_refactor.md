# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation throughput evidence extraction.

Status:
Completed and pushed in `5232aaf7`.

Selected boundary:
Extract explicit and data-rate-derived actual throughput, estimated throughput,
duration resolution, derivation metadata, and downlink-completion evidence into
`OrbitalDynamics.Communications.ContactAllocation.ThroughputEvidence`.
Preserve the existing ContactAllocation public API facade.

Selection evidence:
- Live re-ranking places `contact_allocation.ex` at 3,782 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  RecommendationRiskContext, StationCalendar, LinkCapacity, and
  ResourceProjection.
- The selected helper family owns one contact throughput/downlink evidence
  responsibility used by invalid rows, base allocation rows, and provider
  contact detection.
- Capacity requirements, reduced-capacity packing, contact identity and input
  validation, station availability, contention, approval policy, and report
  aggregation remain outside this boundary.
- Existing public APIs, row fields, alias precedence, numeric-string
  acceptance, derivation formulas, omission behavior, and deterministic output
  remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,912
  files.
- Focused ContactAllocation coverage passed: 70 tests.
- Adjacent operator-review, schema-contract, and validation-fixture coverage
  passed: 24 tests.
- Exact public old/new comparison against selection commit `7873709f` passed
  for eleven allocations covering explicit throughput precedence, MB/s and
  Mbps derivation, duration aliases and fallback, nested evidence, and
  downlink-completion fields.
- `mix xref callers` reports only the ContactAllocation facade as a runtime
  caller of the extracted throughput owner.
- Static ownership checks confirm throughput resolution, rate derivation,
  duration resolution, and downlink-completion evidence live in the dedicated
  owner while validation and allocation remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation throughput evidence extraction, selected in `7873709f` and
implemented in `5232aaf7`.
`contact_allocation.ex` moved from 3,782 to 3,593 lines; the dedicated
throughput owner is 220 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
