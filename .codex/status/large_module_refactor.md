# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention capacity-demand extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `ab0e2883`.
- Implementation was committed and pushed in `c7c37b01`.
- `communications/contact_contention.ex` moved from 2,242 to 1,978 lines.
- `OrbitalDynamics.Communications.ContactContention.CapacityDemand` is a
  317-line owner reached through one private facade delegate.

Verification:
- Strict warning-clean compilation passed across 3,981 files.
- The focused ContactContention file and five adjacent campaign,
  candidate-refresh, operator-review, schema, and validation consumers passed
  together: 62 tests.
- Exact old/new public report/resolution/summary parity passed for 9 chains
  covering direct, throughput-model, capacity-model, and activity-context
  sources, fractions and percentages, precedence, zero/100-percent bounds,
  invalid declarations, missing station IDs, aggregate source/status/station
  routing, and capability metadata.
- `mix xref callers` reports only the ContactContention facade.
- The facade-owned required-capacity attributes and demand/source/validation
  helpers are absent apart from one thin summary delegate, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention capacity-demand extraction, selected in `ab0e2883` and
implemented in `c7c37b01`.
`communications/contact_contention.ex` moved from 2,242 to 1,978 lines; the
dedicated capacity-demand owner is 317 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
