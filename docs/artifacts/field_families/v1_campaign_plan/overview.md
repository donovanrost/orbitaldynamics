# Overview

`campaign_plan.v1` is the current operator-review plan surface. The checked-in
campaign artifact demonstrates. `OrbitalDynamics.campaign_plan/2`,
`OrbitalDynamics.campaign_repair/1`, and
`OrbitalDynamics.campaign_strategy/1` expose the same in-memory V1/V2/V3
planner entry points as the underlying `CampaignPlanner` module, while the
file-backed helpers remain available for JSON request artifacts:

- selected `activities`, source `candidate_activities`, and `ranked_timelines`
- `contact_intents` and `proposed_contacts` for artifact-only Cadence import,
  with contact intents preserving campaign approval-policy evidence when
  supplied
- `optimizer_contract`, `constraint_report`, `score_term_report`, and
  `objective_tradeoff_report`
- `link_capacity_report`, `station_calendar_report`,
  `contact_contention_report`, `contact_contention_resolution_report`, and
  `contact_allocation_report`
- `objective_satisfaction_report`
- `operational_timeline_report`
- `command_window_report` over selected command/tracking/health-check/uplink
  windows, kept artifact-only with no command execution or schedule mutation
- `operator_review_package` with station-contention recommendation,
  contact-allocation, contact-intent approval, command-window, and warning rows
  for artifact-only operator import/review workflows
- `cadence_import_manifest` with proposed-contact import rows for
  artifact-only schedule adapter handoff plus station-contention
  recommendation, embedded operational-timeline, command-window, and
  contact-allocation review rows; campaign, repair, and strategy branch
  contact intents that carry approval evidence become typed
  `review_contact_intent` rows before import, with contact-intent policy gate
  status exposed for adapter queues
- optional `resource_filter_report` when campaign `resource_summaries` suppress
  candidates through the thin availability/margin policy
- optional `resource_projection_report` when campaign `resource_summaries` are
  supplied
