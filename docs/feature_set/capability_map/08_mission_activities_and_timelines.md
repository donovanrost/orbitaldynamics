# 8. Mission Activities and Timelines

OrbitalDynamics models planned and realized mission activities, reconciles them against provider telemetry, and emits review/import artifacts without owning the operational schedule.

Transition-application reports may opt into immutable `timeline_revision.v1`
evidence and a pure replay boundary. The evidence binds canonical SHA-256
identities for the prior timeline revision, named transition batch, and selected
replacement revision; replay returns the same replacement identity or an
inspectable revision/batch conflict without a database, schedule mutation, or
external workflow.

- [Typed Activity Model and Lifecycle](08_mission_activities/typed-activity-model-and-lifecycle.md)
- [Integrity, Rejection, and Preservation Reports](08_mission_activities/integrity-rejection-and-preservation-reports.md)
- [Timeline Feedback Reconciliation](08_mission_activities/timeline-feedback-reconciliation.md)
- [Command-Window Reports and Operational Timeline Builder](08_mission_activities/command-window-and-timeline-builder.md)
- [Lifecycle Helpers, Timeline Diffs, and Transitions](08_mission_activities/lifecycle-helpers-diffs-and-transitions.md)
- [Partial, Near-Term, Later, and Out-of-Scope](08_mission_activities/partial-and-future.md)
