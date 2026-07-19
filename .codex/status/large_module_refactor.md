# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation station-capacity evidence extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract station availability precedence, station-capacity blocking decisions,
station and required capacity fraction/percent parsing, ambiguous-overlap
handling, capacity declaration validation, and required-capacity source
attribution into
`OrbitalDynamics.Communications.ContactAllocation.StationCapacityEvidence`.
Preserve all public ContactAllocation allocation, report, summary,
station-pressure, capacity-pack, reservation-conflict, provider-request, and
capability facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_allocation.ex` at 2,197 lines,
  the largest ordinary eligible facade behind Schema, Timeline, and
  MissionPlan.Activity.
- ContactAllocation already has seven responsibility owners, while
  station-capacity evidence remains split across blocking/availability helpers
  at lines 1,529-1,602, required-capacity attribution at lines 1,710-1,796, and
  candidate/validation helpers at lines 1,932-2,034.
- The facade's advertised station/required fraction, percent, and value paths,
  availability blocking values, and availability precedence remain
  authoritative and will be passed to the owner as policy input.
- Contact normalization/identity, throughput evidence, contention resolution,
  resource filtering, row construction, capacity packing, approval policy,
  summaries, reservation/provider workflows, and artifact contracts remain
  outside the boundary.
- Existing path precedence, fraction/percent conversion and bounds, ambiguous
  overlap exclusion, source attribution, availability severity, blocking
  reasons, and exact invalid-input reasons must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection activity-effect policy extraction, selected in `444f0395`
and implemented in `cd89b612`.
`resource_projection.ex` moved from 2,197 to 1,981 lines; the dedicated
activity-effect policy owner is 246 lines.

Next candidate:
Complete the selected ContactAllocation station-capacity evidence extraction.

Blocked:
No.
