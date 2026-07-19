# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection activity-effect policy extraction.

Status:
Completed and pushed.

Selected boundary:
Extract activity resource-effect classification, including terminal and
approval-state gating, contact-allocation gating, suppressed/incompatible
activity-type matching, payload/antenna availability policy, activity
status/approval lookup, resource direction, and downlink classification, into
`OrbitalDynamics.ResourceProjection.ActivityEffectPolicy`. Preserve all public
ResourceProjection report, flow-report, flow-summary, and capability facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking ties `resource_projection.ex` and
  `communications/contact_allocation.ex` at 2,197 lines, the largest ordinary
  eligible facades behind Schema, Timeline, and MissionPlan.Activity.
- ResourceProjection already has seven responsibility owners, while its
  activity-effect policy remains split between activity-type matching at lines
  624-696 and effect/status/allocation/direction helpers at lines 1,782-1,970.
- The selected helpers form one pure decision boundary consumed by projected
  activity flow rows; the facade can pass its authoritative activity-type alias
  map into the owner without forking normalization policy.
- Activity input normalization/validation, resource-summary normalization,
  projection arithmetic, delivery evidence, margins, pressure classification,
  approval requirements, report assembly, and artifact contracts remain
  outside the boundary.
- Existing precedence and exact reasons for unavailable spacecraft,
  rejection/terminal state, allocation deferral, suppressed/incompatible
  activity types, payload/degraded state, antenna availability, and active
  projection must remain unchanged.

Implementation:
- Selection was recorded and pushed in `444f0395`.
- Implementation was committed and pushed in `cd89b612`.
- `resource_projection.ex` moved from 2,197 to 1,981 lines.
- `OrbitalDynamics.ResourceProjection.ActivityEffectPolicy` is a 246-line
  owner reached through thin private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,983 files.
- The focused ResourceProjection suite and six adjacent campaign,
  candidate-refresh, resource-filter, operator-review, flow-summary, and
  validation consumers passed together: 111 tests.
- Exact old/new public report/flow/capability parity passed for 7 chains
  covering active, terminal, rejected, allocated, deferred, policy-blocked,
  suppressed, incompatible, payload-unavailable, antenna-unavailable,
  degraded, spacecraft-unavailable, and nested-allocation cases.
- `mix xref callers` reports only the ResourceProjection facade.
- The facade-owned effect/allocation/type-matching helpers are absent apart
  from thin delegates used by flow-row assembly and input normalization;
  formatting and `git diff --check` passed, and the final diff is
  ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection activity-effect policy extraction, selected in `444f0395`
and implemented in `cd89b612`.
`resource_projection.ex` moved from 2,197 to 1,981 lines; the dedicated
activity-effect policy owner is 246 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
