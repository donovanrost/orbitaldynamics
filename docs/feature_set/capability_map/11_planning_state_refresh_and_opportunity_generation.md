# 11. Planning State Refresh and Opportunity Generation

This is the bridge from strategy over prior artifacts to real rolling mission planning: a V3 strategy recommendation is only operationally strong when its branches can reason from current state instead of only from old candidate windows. The capability documentation is split into focused sub-files:

- [Refresh Pipeline and Provenance](11_planning_state_refresh/refresh_pipeline_and_provenance.md) — the core V1/V2/V3 refresh manifest, candidate generation, contact allocation, source-report summarization, and provenance contracts.
- [Mission-State Fallbacks and Feedback Overlays](11_planning_state_refresh/mission_state_fallbacks_and_feedback_overlays.md) — V2 repair refresh, mission-state catalogs, objective canonicalization, operational-feedback ingestion, and branch-derived feedback refreshes.
- [Resource, Contact, and Objective Pressure Replay](11_planning_state_refresh/pressure_replay_into_branch_refresh.md) — replay of resource-projection, resource-filter, contact-filter, contact-allocation, contact-contention, link-capacity, objective-satisfaction, objective-tradeoff, and score-term rows into branch-local refresh pressure.
- [Timeline-Diff and Transition-Application Replay](11_planning_state_refresh/timeline_diff_replay.md) — constraint and timeline-diff replay into branch-local feedback across observations, contacts, commands, maneuvers, and resources.
- [Candidate-Diff, Strategic Additions, and Downlink-Completion Staging](11_planning_state_refresh/candidate_diff_and_strategic_additions.md) — objective-satisfaction-into-objectives, V2 candidate-diff replacement, semantic similarity, urgent-target and downlink-completion staging, freshness, and allocation policy.
- [Lifecycle, Roadmap, and Closing](11_planning_state_refresh/lifecycle_and_roadmap.md) — `partial`, `near-term`, `later`, and `out of scope` capability lifecycle entries plus the closing framing.
