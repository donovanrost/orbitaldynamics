# Level 5: Strategy/Orchestration Planner V3

Feature complete when mission-state snapshots, explicit and derived what-if
branches, V2 repair, resource summaries, operational feedback, action-specific
approval policy, and structured recommendation explanations can be compared in
one reproducible strategy artifact.

Status: `implemented` as a deterministic strategy slice, `partial` as mature
orchestration. Supplied `candidate_refresh.v1.operational_feedback` now
participates in the same deterministic merge as prior-plan and mission-state
feedback, while explicit request feedback remains the final authority; V3
artifacts expose per-key effective and overridden feedback sources for audit.
Candidate-refresh manifests can also carry provider-shaped
`operational_feedback.realized_activities` rows with nested `target`, `station`,
`ground_station`, `spacecraft`, or `satellite` identity objects; refresh generation reconciles those rows
through the same timeline-feedback path and derives ordinary station, target,
and downlink-demand feedback maps before scoring candidates, while provenance
records that the maps came from realized rows, how many rows were consumed, and
which malformed provider-shaped realized identities were excluded from the
effective refresh feedback; review/import warning handoffs now preserve the
invalid `source_operational_feedback` map beside the provenance so later strategy
replay can retain it as review-only evidence. Candidate-refresh operational
feedback factor maps now require clean unit-interval values for success,
quality, and throughput factors, preserving out-of-range entries as invalid
feedback sections instead of clamping them into refreshed candidate scoring.
Remaining work includes robust branch generation, combined futures, calibrated
resource dynamics, and stronger recommendation selection.

