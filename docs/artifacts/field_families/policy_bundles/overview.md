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

