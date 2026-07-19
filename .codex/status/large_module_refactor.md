# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity downlink-requirement projection extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract report/station required-downlink resolution, policy station-value
normalization, invalid station diagnostics, contact requirement/source
projection, selected and actual shortfall/status calculation, and actual
completion ratio into
`OrbitalDynamics.Communications.LinkCapacity.DownlinkRequirement`. Preserve all
public LinkCapacity report and summary facades.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 2,462
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 2,024-2,267 and exclusively owns
  required-downlink evidence and completion-state projection.
- Report construction and per-station row construction are the only consumers
  of the requirement projection entry points.
- Estimated/actual throughput derivation, capacity adjustment, contact
  eligibility, station evidence, approval policy, summary aggregation, public
  clauses, and artifact contracts remain outside this boundary.
- Existing report-policy/station-policy/contact precedence, stable station-ID
  validation, numeric-string coercion, invalid-key rendering, positive-value
  guards, source-list precedence, contact-ID fallback sources, nil/empty
  behavior, shortfall/status thresholds, and unit-interval clamping must remain
  unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention priority-override normalization extraction, selected in
`fab92d36` and implemented in `b46b3b30`.
`communications/contact_contention.ex` moved from 2,466 to 2,370 lines; the
dedicated priority-overrides owner is 134 lines.

Next candidate:
Complete and verify the selected LinkCapacity downlink-requirement projection
extraction.

Blocked:
No.
