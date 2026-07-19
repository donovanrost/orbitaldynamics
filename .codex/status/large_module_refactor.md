# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection activity-effect policy extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
Study.Manifest schema-document extraction, selected in `4beb22bd` and
implemented in `d80ce4e9`.
`study/manifest.ex` moved from 2,229 to 1,621 lines; the dedicated schema
document owner is 632 lines.

Next candidate:
Complete the selected ResourceProjection activity-effect policy extraction.

Blocked:
No.
