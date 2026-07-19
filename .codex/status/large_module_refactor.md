# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity throughput evidence extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback realized feedback validation extraction, selected in
`75aca312` and implemented in `60020f26`.
`timeline_feedback.ex` moved from 2,267 to 1,993 lines; the dedicated realized
feedback validation owner is 294 lines.

Next candidate:
Implement and verify the selected LinkCapacity throughput-evidence boundary.

Blocked:
No.
