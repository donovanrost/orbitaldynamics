# Plan Structure and Lifecycle

## Planning Product Types

Different users need different planning products. The toolkit should make the
product type explicit so downstream systems know how to review and import the
artifact.

Candidate product types:

- daily operations plan
- weekly campaign plan
- anomaly recovery plan
- maneuver plan
- contact-only plan
- payload collection plan
- engineering analysis plan
- not-for-execution trade study
- operator review package
- customer delivery forecast
- resource risk forecast
- ground-network reservation proposal
- command-window review package

Each product type can define required fields, quality gates, model fidelity
requirements, approval requirements, and import eligibility.

## Hierarchical Planning

Mission planning happens at multiple time scales.

Planning horizons:

- annual or quarterly campaign planning
- monthly capacity planning
- weekly objective planning
- daily operations planning
- pass/contact planning
- command sequence planning
- real-time replanning
- anomaly response planning

Each horizon has different fidelity, latency, approval, and output needs.
Strategic plans can tolerate approximate models and longer runtimes. Contact or
command-adjacent plans need fresher state, stricter quality gates, and clearer
authority boundaries.

Hierarchical planning should preserve links between:

- strategic objectives
- campaign allocations
- daily plans
- pass-level activities
- command products
- realized outcomes

## Plan Lifecycle

A plan has a lifecycle. It is not only generated once.

Lifecycle states:

- draft
- analyzed
- review-ready
- under review
- approved
- imported
- partially executed
- executed
- superseded
- canceled
- archived
- reconciled against reality

The mature planner should preserve lifecycle state and prevent invalid
transitions. For example, an executed activity should not be silently moved by a
repair plan, and a not-for-execution trade study should not become importable
without explicit review.

## Plan Merge and Conflict Resolution

Real operations often receive changes from multiple teams or planning products.

Feature areas:

- merge payload plan with contact plan
- merge maneuver constraints into existing schedule
- merge anomaly recovery procedure with baseline plan
- detect conflicting deltas
- preserve locked, approved, and executed activities
- identify conflicting authority boundaries
- explain why one change wins
- produce operator-resolvable conflicts
- track conflict resolution decisions
- emit merged plan provenance

Merge behavior should be deterministic and reviewable. The planner should not
silently discard one team's plan delta.

## Constraint Library

Reusable named constraints make plans easier to understand, test, and configure.

Candidate constraints:

- minimum power reserve
- maximum recorder fill
- minimum fuel margin
- no payload activity in eclipse
- no maneuver during contact
- no imaging over restricted region
- minimum contact duration
- maximum schedule churn
- maximum operator approvals
- station reservation respected
- payload duty-cycle limit
- thermal cooldown required
- command authority required
- no activity with stale accepted state

Constraints should expose:

- identifier
- version
- applicable activity types
- applicable mission phases
- input fields
- result status
- violation reason
- severity
- validation level
- traceability references

## Objective Library

Reusable named objectives make V1/V2/V3 scoring and strategy explanations more
consistent.

Candidate objectives:

- maximize target coverage
- maintain revisit cadence
- minimize data latency
- maximize downlink completion
- preserve fuel
- preserve battery margin
- balance spacecraft utilization
- minimize operator workload
- minimize schedule churn
- satisfy customer priority
- maximize delivery confidence
- preserve healthy fleet capacity
- reduce degraded-mode exposure

Objectives should expose score terms, direction, priority, traceability
references, and explanation rows.

## Explainable Rejection Catalog

Operators need to know why candidates and alternatives were rejected.

Candidate rejection reasons:

- no access window
- no target visibility window
- eclipse conflict
- battery margin too low
- storage full
- fuel margin too low
- payload unavailable
- antenna unavailable
- station unavailable
- station reserved
- station capacity reduced
- contact too short
- target already satisfied
- better spacecraft assigned
- activity overlaps locked timeline item
- command authority missing
- policy blocked
- stale state
- model incompatible
- quality gate failed

Rejection rows should preserve candidate ID, affected activity type, source
window, violated constraint, required margin, actual margin, and reviewability.
Existing `operational_timeline_report.v1` artifacts are accepted as idempotent
inputs by the operational timeline report facade when downstream queues already
hold the root timeline artifact.
Current `candidate_rejection_report.v1` support is artifact-only: it preserves
declared and locally derived rejection reasons, source-window/timeline identity,
violated-constraint and margin evidence, reviewability, deterministic reason
counts, and row-derived candidate ID sets for rejected, not-rejected,
reviewable, invalid-input, and reason-keyed routing. Reduced station capacity
can be derived from direct/nested station-capacity fractions or nested
station-calendar reduced/degraded status evidence without selecting candidates
or mutating schedules. Generated reports carry the exact candidate-rejection
`model_limits` list, and runtime validation plus schema export pin that list for
schema-only handoffs. Existing `candidate_rejection_report.v1` artifacts are
accepted as idempotent inputs by the candidate-rejection report facade when
downstream queues already hold the standalone explanation artifact.
Transition-application summaries are also artifact-only: they preserve selected
activity IDs, selected/review/preserved/recorded/withheld timeline ID sets,
review-gated application rows, decision counts, and selected timeline-integrity
counts from `timeline_transition_application_report.v1` without approving
operators, writing schedules, or executing commands. Existing
`timeline_transition_application_report.v1` artifacts are accepted as
idempotent inputs by the transition-application report facade when downstream
queues already hold the standalone transition artifact.
Schema-backed transition-application summaries can also route through the public
operator-review and Cadence-import facades as
`timeline_transition_application_summary.v1` handoffs that preserve review
applications plus selected/review timeline ID maps without mutating schedules.
Lifecycle preservation summaries are artifact-only as well: they preserve
preserve/review-change/mutable activity ID sets, preservation-sensitive activity
and timeline ID sets, protection-category-keyed activity ID sets, decision and
category/reason counts, activity/timeline ID sets by decision, category, and
reason, and no-mutation assumptions before repair or import selection. Batch
`timeline_preservation_report.v1` and single-activity
`timeline_preservation_status.v1` artifacts route through the public
operator-review and Cadence-import facades as adapter-only preservation review
rows, separating ready-to-record preservation evidence from review-required
invalid or changed protected activity evidence. Generated preservation reports
and single-activity statuses also carry the timeline model-limit list, and
runtime validation plus schema export pin that list against
`OrbitalDynamics.Timeline.model_limits/0`.
Single-activity lifecycle-state helpers provide a smaller review/import
preflight for adapters that only need normalized planned/realized status,
approval, lock, executed, and protection evidence without applying a repair plan
or mutating the schedule. The compact status, approval, and combined lifecycle
handoffs are validated as `timeline_activity_status_state.v1`,
`timeline_activity_approval_state.v1`, and
`timeline_activity_lifecycle_state.v1`; generated status-state,
approval-state, and lifecycle-state handoffs also carry the exact timeline
`model_limits` list in runtime validation and schema export. The public
operator-review and Cadence-import facades route those artifacts directly for
adapter-only preflight review or ready-for-import classification.
Timeline-diff summaries provide the same compact triage surface for
`timeline_diff_report.v1`, preserving review rows, changed-field counts,
transition decision counts, added/removed/changed/unchanged timeline ID sets,
duplicate identity IDs, invalid source/replacement input IDs, and no-authority
assumptions. Existing `timeline_diff_report.v1` artifacts are accepted as
idempotent inputs by the diff-report facade when downstream queues already hold
the standalone diff artifact. Schema-backed diff summaries can also route
through the public operator-review and Cadence-import facades as
`timeline_diff_summary.v1` handoffs that preserve review rows and summary-level
timeline ID maps without mutating schedules.

## Plan Diff and Audit Trail

Timeline diff is useful, but mature planning needs a broader plan audit trail.

Diff areas:

- changed activities
- changed contacts
- changed command products
- changed objective satisfaction
- changed resource margins
- changed risk posture
- changed approvals
- changed policy decisions
- changed model assumptions
- changed input freshness
- changed validation level
- changed import readiness

Plan diffs should be suitable for operator review, automated quality gates, and
long-term audit.

## Plan Publication and Subscription

Once a plan changes, other systems and teams need to know.

Feature areas:

- publish plan artifacts
- subscribe to plan updates
- notify affected teams
- mark superseded artifacts
- publish dependency impact reports
- invalidate downstream products
- link replacement artifacts
- preserve publication sequence
- expose changed-field summaries
- record publication authority

Current implementation note: `Timeline.dependency_impact_summary/3` and
`OrbitalDynamics.timeline_dependency_impact_summary/3` provide the artifact-only
dependency-impact summary for source/replacement timelines. They identify
activities whose dependencies or explicit exclusivity links still point at
changed or removed source timeline identities and keep the result as review
evidence, including scoped dependent IDs and impacted dependency/exclusivity
IDs, rather than publication or operator authority. The same artifact can be
promoted through `OperatorReview.from_timeline_dependency_impact_summary/1` and
`CadenceImport.from_timeline_dependency_impact_summary/2` into review-required
handoff rows that carry source/replacement scope, scoped dependent IDs, and
impacted IDs without changing schedules. The generic
`OrbitalDynamics.operator_review_package/1` facade routes those
dependency-impact summaries to the same review package path.
`Timeline.integrity_report/2` and
`OrbitalDynamics.timeline_integrity_report/2` also expose row-derived routing
IDs for dependency/exclusivity integrity review, including review activity and
timeline IDs, invalid-input IDs, issue-type counts, and flattened missing,
self, cycle, order, and exclusivity evidence IDs without mutating schedules.
Those schema-backed integrity reports can be promoted through the public
operator-review and Cadence-import facades as `timeline_integrity_report.v1`
source-artifact handoffs with `timeline_integrity_review` rows that preserve
the source integrity row and dependency/exclusivity issue IDs without mutating
schedules.
`Timeline.publication_summary/2` and
`OrbitalDynamics.timeline_publication_summary/2` also accept optional
`timeline_diff_summary.v1` evidence so publication metadata can preserve
changed-field counts, changed/review timeline IDs, and changed-field routing for
audit and downstream invalidation decisions. The publication summary nests the
source diff summary and exposes only derived audit fields; it does not publish
notifications, import replacements, mutate schedules, or grant operator
authority.
CandidateRefresh also accepts those direct or result-artifact-wrapped integrity
reports as source-report provenance, preserving row-derived review/action maps,
dependency and exclusivity evidence IDs, source paths, trust boundaries, and
branch-local integrity pressure without mutating timelines or selecting
candidates.
Programmatic `MissionPlan` validation uses the same integrity report before
scenario compilation, including missing activity-ID and timeline-ID dependency
checks.

`Timeline.publication_summary/2` and
`OrbitalDynamics.timeline_publication_summary/2` emit schema-backed
`timeline_publication_summary.v1` metadata for publication handoff. The summary
records deterministic publication ID and sequence, source artifact identity,
superseded artifact IDs, downstream product IDs, invalidated downstream product
IDs, optional dependency-impact status/counts, publication authority token,
model limits, and an explicit artifact-only no-schedule-mutation/no-delivery
boundary. Cadence or another host system still owns actual notification
delivery, import authority, and publication execution.
