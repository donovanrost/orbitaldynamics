# Integrity, Rejection, and Preservation Reports

## Candidate rejection report

`candidate_rejection_report.v1` now preserves declared and locally derived candidate rejection explanations. It carries:

- Candidate/timeline/source-window identity.
- Canonical rejection reasons.
- Typed station-capacity `unit`/`path` metadata for reduced-capacity rejection
  derivation, including direct, metadata, and nested source-station-calendar
  `capacity_pack_capacity_fraction`.
- Nested source-station-calendar availability/status evidence for station
  unavailable, reserved, and reduced-capacity rejection derivation.
- Optional violated-constraint and margin evidence.
- Reviewability.
- Row-derived reason/action counts that export and validate as non-negative integer maps.
- Rejected, not-rejected, reviewable, invalid-input, and reason-keyed candidate ID sets.

Executable validation checks these against rows, and `Timeline.capabilities/0` advertises them for catalog consumers — without selecting candidates or mutating schedules.

Reviewable rejected rows flow through `candidate_rejection_review` and `review_candidate_rejection` Cadence-import handoff rows.

## Timeline integrity report

`Timeline.integrity_report/2` and `OrbitalDynamics.timeline_integrity_report/2` now expose the same dependency/exclusivity validation as a compact validated `timeline_integrity_report.v1` **artifact-only** summary. It includes:

- Review rows.
- Row-derived issue counts.
- Issue-type count maps.
- Review activity and timeline ID sets.
- Dependency/exclusivity review ID sets.
- Invalid-input IDs.
- Flattened missing/self/cycle/order/exclusivity evidence IDs for review/import routing.

`Timeline.capabilities/0` advertises those integrity summary/count and issue ID-set semantics, while keeping self-dependency IDs separate from missing dependency IDs.

Executable validation checks the review-row-derived status, review counts,
issue counts/type maps, review activity/timeline ID maps, flattened dependency
and exclusivity evidence IDs, assumptions, and model limits against the emitted
integrity rows.

CandidateRefresh accepts direct, accepted-state, mission-state, and
result-artifact-wrapped `source_timeline_integrity_report` /
`timeline_integrity_report` inputs as source-report provenance. Its
timeline-integrity replay summary preserves row-derived issue/review counts,
issue-type and required-action maps, review activity/timeline routing,
dependency/exclusivity evidence IDs, source paths, and trust-boundary evidence
without mutating timelines, selecting candidates, approving imports, or writing
to Cadence.

Operational timeline validation fixtures now also check row-derived operational-kind, status, approval, Cadence-import, required-action, integrity-issue, and row-ID routing maps.

### Integrity issue types and evidence

Timeline-integrity issue types are schema-visible and executable-validation backed for:

- Invalid inputs.
- Dependency cycles/order/missing-self checks.
- Exclusivity overlap reviews.

The detailed integrity issue objects validate their type-specific required evidence, stable-ID values, and reason/group fields instead of remaining arbitrary review maps.

Integrity counts, issue-type summaries, and flattened evidence ID lists are cross-checked against the detailed issue objects across operational, feedback, diff, command-window, and contact-intent surfaces, so hand-authored timeline artifacts cannot publish contradictory review summaries.

## Capability surface and facade discovery

`Timeline.capabilities/0` publishes the following helper names, plus matching `OrbitalDynamics` facade names, so adapters can discover typed activity normalization and executable lifecycle helpers without depending on private module layout:

- Normalization.
- Identity/context.
- Stable-identity path metadata.
- Candidate-rejection.
- Integrity.
- Transition.
- Single-activity protection.
- List-level lifecycle preservation.

## Activity state facade

`TimelineFeedback.activity_state/3` and `OrbitalDynamics.timeline_activity_state/3` now expose a compact planned/realized activity-state facade over the same reconciliation engine. It returns:

- Normalized source and realized contexts.
- Status transition.
- Protection decision.
- Match strategy.
- Review flags.
- Row-derived status, feedback-kind, match-strategy, Cadence-import-status, and
  protection-decision count maps.
- Model limits.
- Row-level evidence.

It does this without mutating schedules or executing commands. Unmatched planned/realized pairs are preserved as review-required rows.

## Preservation report

`Timeline.preservation_report/2` and `OrbitalDynamics.timeline_preservation_report/2` provide a compact validated `timeline_preservation_report.v1` **artifact-only** summary of locked, approved, executed, or invalid selected activities that need preservation or review before repair/import selection. `Timeline.preservation_status/2` and `OrbitalDynamics.timeline_preservation_status/2` expose the single-activity `timeline_preservation_status.v1` preflight. This includes:

- Preserve, review-change, mutable, preservation-sensitive, and protection-category-keyed activity/timeline ID sets derived from the report rows.

`Timeline.capabilities/0` advertises the preservation status/count, protection count, and category ID-set row semantics.

## Transition application summary

`Timeline.transition_application_summary/1`/`3` and `OrbitalDynamics.timeline_transition_application_summary/1`/`3` provide a compact selected/review-gated transition summary over `timeline_transition_application_report.v1`. It includes:

- Selected, review-required, preserved-source, recorded-replacement, and withheld-review timeline ID sets.
- Review timeline ID maps by required action and transition category.
- Capability-advertised application-status, transition-decision, transition-count, and transition-category count semantics derived from application rows.

This lets quality gates and import adapters route transition work without walking every application row.

The single-activity transition-decision helper applies the same selected timeline-integrity dependency gate as transition application, so unchanged rows with missing dependencies are reviewable before downstream import selection.

Operator-review packages and Cadence-import manifests preserve source/replacement and selected self-dependency evidence from diff and transition-application rows, instead of flattening it into missing-dependency fields.

## Dependency impact summary

`Timeline.dependency_impact_summary/3` and `OrbitalDynamics.timeline_dependency_impact_summary/3` identify source and replacement activities whose dependency or explicit exclusivity lists still point at changed or removed source timeline identities. They emit the schema-backed `timeline_dependency_impact_summary.v1` artifact, whose executable validator rejects stale row-derived dependent counts and dependency/exclusivity ID sets. They return:

- Review rows.
- Row-derived source/replacement dependent ID sets.
- Impacted dependency/exclusivity ID sets advertised by `Timeline.capabilities/0`.

This is done without mutating schedules or approving work.

## Operational timeline and realized-activity contracts

Operational timeline and realized-activity contracts now type planned fixed-rate aliases plus realized actual data-rate and duration telemetry fields used by timeline-feedback throughput derivation and branch-local refresh, so provider handoff artifacts can lint those data-rate rows before planner consumption.

### Schema-visible vocabularies

- **Lifecycle and approval statuses** — Operational timeline lifecycle statuses and approval statuses are now schema-visible from the same capability surface, so unsupported provider lifecycle or approval states are preserved as review-gated invalid activity rows instead of entering persisted rows as arbitrary strings.
- **Required operator actions** — Also schema-visible from `Timeline.capabilities/0`, keeping monitor, prepare-import, review, resolve, and duplicate/integrity routing vocabulary aligned with executable validation.
- **Cadence import status routing** — Likewise schema-visible, so present/invalid/missing/not-applicable import boundaries cannot drift into arbitrary operational timeline row values.
- **Execution boundary** — The artifact-only `execution_boundary` is constrained to `planned_not_commanded` in exported schema and executable validation.

## V2 plan-delta and repair metadata

- V2 plan-delta rows now expose explicit source/replacement activity-context maps and timeline links, and V2 plan-delta operator-review rows lift those timeline identities for Cadence-facing import/review products.
- Reusable activity context now flattens station-calendar entry and provider-calendar provider/entry identity from nested provider source evidence, while preserving the full source entry and overlap audit trail.
- V2 repair metadata summarizes preserved and changed locked, approved, and executed timeline items under `timeline_protection`.
