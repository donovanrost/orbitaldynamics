# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation station-capacity evidence extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `fb4cb586`.
- Implementation was committed and pushed in `e60823d7`.
- `communications/contact_allocation.ex` moved from 2,197 to 1,953 lines.
- `OrbitalDynamics.Communications.ContactAllocation.StationCapacityEvidence`
  is a 315-line owner reached through thin private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,984 files.
- The focused ContactAllocation suite and six adjacent capacity-pack,
  candidate-refresh, campaign, operator-review, schema, and validation
  consumers passed together: 106 tests.
- Exact old/new public allocation/report/specialized-summary/capability parity
  passed for 7 chains covering direct fractions and percentages, nested
  throughput/capacity/activity sources, source entries and overlaps, ambiguous
  overlaps, availability and zero-capacity blocking, and invalid declarations.
- `mix xref callers` reports only the ContactAllocation facade.
- The facade-owned availability/capacity candidate, parsing, validation, and
  attribution helpers are absent apart from thin delegates; formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation station-capacity evidence extraction, selected in
`fb4cb586` and implemented in `e60823d7`.
`communications/contact_allocation.ex` moved from 2,197 to 1,953 lines; the
dedicated station-capacity evidence owner is 315 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
