# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention capacity-demand extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract required-capacity fraction/percent path policy, declaration validation,
source attribution, selected/deferred capacity-demand row construction,
aggregate totals by status/station/source, and deterministic contact-ID routing
into `OrbitalDynamics.Communications.ContactContention.CapacityDemand`.
Centralize the advertised required-capacity paths and source values with that
owner. Preserve all public ContactContention report, resolution, summary, and
capability facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_contention.ex` at 2,242 lines,
  the largest eligible facade behind Schema, Timeline, MissionPlan.Activity,
  and the root public facade.
- The selected resolution-summary demand builder spans lines 606-699, its
  source routing spans lines 1,210-1,227, and required-capacity resolution spans
  lines 1,303-1,433.
- Only selected/deferred source contact candidates participate; grouping,
  recommendation choice, approval policy, and other resolution-summary fields
  consume the resulting map but do not define its capacity semantics.
- Station availability/capacity context, contention grouping, resolution
  selection policy, feedback/timing, contact validation, public clauses, and
  artifact contracts remain outside this boundary.
- Existing contact/throughput-model/capacity-model/activity-context precedence,
  fraction/percent validation, first-valid path selection, selected/deferred
  filtering, nil total behavior, station omission without stable ID, source
  frequencies, stable dedup/sort, exact map keys, and capability metadata must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity throughput evidence extraction, selected in `a27627e3` and
implemented in `4817d7dc`.
`communications/link_capacity.ex` moved from 2,246 to 1,904 lines; the
dedicated throughput-evidence owner is 426 lines.

Next candidate:
Implement and verify the selected ContactContention capacity-demand boundary.

Blocked:
No.
