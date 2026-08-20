# Policy Bundles Overview

`policy_bundle.v1` rows are reusable artifact-only approval classifiers. They
do not approve, schedule, or execute work. `OrbitalDynamics.policy_bundles/0`,
`OrbitalDynamics.policy_bundle!/1`,
`OrbitalDynamics.policy_bundle_artifact!/1`,
`OrbitalDynamics.policy_bundle_artifacts/0`,
`OrbitalDynamics.normalize_approval_policy/1`,
`OrbitalDynamics.organization_policy_bundle/3`, and
`OrbitalDynamics.policy_decision/5` expose bundle lookup, deterministic
normalization, organization-specific bundle construction, and policy decision
classification at the top-level API. Built-in bundle artifacts and
organization-specific bundles carry schema-validated `model_limits` copied from
`Policy.capabilities/0`, so standalone policy-bundle import gates can inspect
the artifact-only boundary before a decision is produced. Organization-specific bundles remain
artifact-only, but their adapter, organization, and source provenance is now
preserved as `policy_decision.v1.policy_bundle_provenance` whenever such a
bundle classifies a decision. Built-in bundles currently include:

- `default_v1`
- `command_contact_authority_v1`
- `contact_command_review_v1`
- `conservative_ops_v1`
- `timeline_protection_v1`
- `degraded_payload_guard_v1`
- `mission_ops_escalation_v1`
- `ground_network_allocation_v1`
- `maneuver_authority_v1`
- `operator_review_queue_authority_v1`
- `resource_projection_authority_v1`

## Authority Context

`authority_context.v1` is optional caller-supplied evidence for the bounded V3
strategy policy path. It requires `authority_context_id`, `authority_source`,
`source_revision`, `effective_from`, `valid_until`, and `evaluation_time`; the
identity is derived from the remaining canonical fields, so changing a revision
or bound invalidates the prior identity. `evaluation_time` is supplied by the
caller and validation performs no wall-clock read. The validity interval is
lower-bound inclusive and `valid_until` exclusive.

When `Policy.decide/6` receives `authority_context_mode: :explicit`, valid
context is copied into the decision and its campaign-strategy recommendation,
operator-review package, and Cadence import manifest. Its evidence evaluation
does not override substantive policy classification: an already blocked
decision and every downstream eligibility/import-readiness field remain
blocked or non-eligible. Missing, malformed, not-yet-effective, or stale
explicit evidence becomes a deterministic `non_eligible` /
`blocked_by_policy` evaluation carrying its reason and canonical typed caller
evidence. Validators recompute that evaluation rather than trusting copied
maps.

Only absence of both mode and context uses the unchanged `Policy.decide/5`
behavior. A context without mode or any supplied unsupported mode fails closed
with typed evidence. This contract performs no authority lookup, approval,
scheduling, Cadence write, or execution.
