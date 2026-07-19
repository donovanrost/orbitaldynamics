# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity throughput evidence extraction.

Status:
Completed and pushed.

Selected boundary:
Extract capacity-adjusted estimated throughput, actual throughput/completion
evidence selection and contact-ID resolution, explicit and data-rate-derived
throughput precedence, duration/rate unit handling, derivation artifacts,
completion fraction precedence, unresolved contact routing, and aggregate
throughput/completion calculations into
`OrbitalDynamics.Communications.LinkCapacity.ThroughputEvidence`. Preserve all
public LinkCapacity report, summary, relay-summary, and capability facades.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 2,246 lines, the
  largest eligible facade behind Schema, Timeline, MissionPlan.Activity, and
  the root public facade.
- The selected throughput family spans lines 1,563-1,971 and exclusively owns
  estimated/actual throughput, completion, rate/duration derivation, and
  selected-contact evidence resolution.
- Report construction consumes this family through private helper calls; no
  public clause or artifact schema depends on the helpers directly.
- Input validation, contact normalization/identity policy, station calendar/
  reservation summaries, required-downlink policy, approval policy, report
  summary construction, and relay paths remain outside this boundary.
- Existing explicit-over-derived precedence, top-level-over-model precedence,
  MB/s versus Mbps conversion, nonnegative rate clamp, actual-duration
  precedence, strict unit-interval completion selection, duplicate/ambiguous/
  unmatched contact routing, deterministic sorting, nil aggregate semantics,
  exact derivation maps, and floating-point behavior must remain unchanged.

Implementation:
- Selection was recorded and pushed in `a27627e3`.
- Implementation was committed and pushed in `4817d7dc`.
- `communications/link_capacity.ex` moved from 2,246 to 1,904 lines.
- `OrbitalDynamics.Communications.LinkCapacity.ThroughputEvidence` is a
  426-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,980 files.
- The focused LinkCapacity file and five adjacent strategy, candidate-refresh,
  operator-review, and schema consumers passed together: 74 tests.
- Exact old/new public report/capability parity passed for 11 cases covering
  explicit and rate-derived estimates, capacity and unavailability, MB/s and
  Mbps actuals, actual-duration precedence, nested throughput-model evidence,
  completion aliases, unmatched/ambiguous contact IDs, explicit precedence,
  derivation artifacts, and capability metadata.
- `mix xref callers` reports only the LinkCapacity facade.
- The facade-owned throughput/rate/duration/completion derivation and
  resolution helpers are absent apart from thin delegates, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity throughput evidence extraction, selected in `a27627e3` and
implemented in `4817d7dc`.
`communications/link_capacity.ex` moved from 2,246 to 1,904 lines; the
dedicated throughput-evidence owner is 426 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
