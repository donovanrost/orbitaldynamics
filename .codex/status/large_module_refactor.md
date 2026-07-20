# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-artifact validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add TimelineArtifactValidation owner-default entry points for the 17 direct
timeline diff, integrity, publication, activity-state, lifecycle,
preservation, feedback, and transition artifacts. Derive requirements from the eight
existing timeline registry modules and model limits from
TimelineCapabilityContext, then route the Schema clauses directly. Keep every
artifact-specific contract/validation API unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,034 lines; the other
  targeted public facades are now 164 to 524 lines.
- Seventeen direct clauses repeat required-field setup and family owner routing.
- Eight timeline registry modules collectively own every required-field list.
- TimelineCapabilityContext owns both timeline and feedback model limits.
- OperationalTimelineValidation and TimelineTransitionValidation already own
  their default validation context.
- All remaining artifact-specific validators are dedicated contract modules;
  no route needs recursive Schema lookup or facade-local callbacks.

Implementation:
Added TimelineArtifactValidation with one registry-backed family entry point,
17 artifact routes, timeline/feedback model-limit ownership, operator-review
context for feedback reports, and preserved owner-default operational/transition
paths. Routed every direct Schema timeline-family clause to the owner and
removed two stale facade aliases. `schema.ex` moved from 5,034 to 4,958 lines.

Verification:
- Strict timeline/Cadence/campaign baseline before extraction: 17 passed.
- The same strict focused suite after extraction: 17 passed.
- Strict timeline validation, operator-review, feedback, and transition
  coverage: 155 passed.
- Strict schema and JSON Schema export coverage: 18 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms 17 direct owner routes and no remaining
  facade-local timeline-family validation logic.
- Registry inspection confirms all selected contracts are covered without
  duplicate keys across the eight owner registries.
- `mix xref callers OrbitalDynamics.Schema.TimelineArtifactValidation` reports
  only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,076 files with no warnings.
- Bounded local review confirmed required-field, model-limit, callback, issue
  ordering, and operational-timeline no-duplicate-validation behavior.
- Implementation commit `e84783b5` pushed to `main`.

Behavior/schema changes:
None. Required fields, model limits, validation ordering and paths, public
Schema APIs, validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema timeline-artifact validation context extraction, selected in `f2d5e2df`,
inventory-corrected in `67c69b6f`, and implemented in `e84783b5`.
`schema.ex` moved from 5,034 to 4,958 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters. Preserve the
context-bearing CommonJsonSchema wrappers unless a separate exact ownership
boundary is proven.

Blocked:
No.
