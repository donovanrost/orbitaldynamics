# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity downlink-requirement projection extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `defe0c62`.
- Implementation was committed and pushed in `f7c379d7`.
- `communications/link_capacity.ex` moved from 2,462 to 2,246 lines.
- `OrbitalDynamics.Communications.LinkCapacity.DownlinkRequirement` is a
  270-line owner reached through private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,968 files.
- The focused LinkCapacity file and six adjacent repair, strategy, replay,
  operator-review, and Cadence-import consumers passed together: 86 tests.
- Exact old/new public parity passed for 9 cases covering global, station, and
  contact requirement precedence; invalid station IDs; nested requirement
  paths; explicit and fallback sources; negative and malformed policy values;
  selected and actual completion metrics; and capability metadata.
- `mix xref callers` reports only the LinkCapacity facade.
- The removed requirement/source/status helpers and facade-owned path
  attributes are absent apart from thin delegates, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity downlink-requirement projection extraction, selected in
`defe0c62` and implemented in `f7c379d7`.
`communications/link_capacity.ex` moved from 2,462 to 2,246 lines; the
dedicated downlink-requirement owner is 270 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
