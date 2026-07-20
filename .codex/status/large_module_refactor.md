# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-artifact validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add TimelineArtifactValidation owner-default entry points for the 14 direct
timeline diff, integrity, publication, activity-state, lifecycle,
preservation, and transition artifacts. Derive requirements from the seven
existing timeline registry modules and model limits from
TimelineCapabilityContext, then route the Schema clauses directly. Keep every
artifact-specific contract/validation API unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,034 lines; the other
  targeted public facades are now 164 to 524 lines.
- Fourteen direct clauses repeat required-field setup and family owner routing.
- Seven timeline registry modules collectively own every required-field list.
- TimelineCapabilityContext owns both timeline and feedback model limits.
- OperationalTimelineValidation and TimelineTransitionValidation already own
  their default validation context.
- All remaining artifact-specific validators are dedicated contract modules;
  no route needs recursive Schema lookup or facade-local callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, model limits, validation ordering and paths,
public Schema APIs, validation results, and checked-in exports must remain
unchanged.

Last completed slice:
Schema campaign-artifact validation context extraction, selected in `706b4bea`
and implemented in `633eab11`.
`schema.ex` moved from 5,191 to 5,034 lines.

Next candidate:
Implement and verify the selected timeline-artifact validation context
extraction, then re-rank the remaining Schema responsibility clusters.

Blocked:
No.
