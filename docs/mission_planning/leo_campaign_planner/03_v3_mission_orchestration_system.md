# V3: Mission Orchestration System

LEO Constellation Campaign Planner V3 becomes a mission orchestration system.

It answers:

> Across possible futures, what is the best operational strategy for the
> constellation, and why?

## Digital Twin Planning

V3 should maintain a living model of the constellation:

- current orbit estimates,
- spacecraft health,
- subsystem constraints,
- onboard storage,
- battery and power state,
- maneuver history,
- payload availability,
- ground-network availability,
- known failures and degraded modes.

The planner stops being fed a static input file and instead plans against a
continuously updated mission state.

## Strategic Campaign Optimization

V3 should optimize across campaign-level goals:

- maintain regional or global coverage,
- prioritize customer or mission commitments,
- minimize collection-to-downlink latency,
- preserve fuel across fleet lifetime,
- balance asset usage,
- defer lower-value activities when risk is high,
- choose between competing campaigns.

This is the level where the planner can answer:

> What is the best way to run this constellation this week?

## What-If and Branch Planning

V3 should compare alternate futures:

- What if a ground station is unavailable for six hours?
- What if a spacecraft misses its maneuver?
- What if an urgent target request is accepted?
- What if low-value collections are deprioritized?
- What if fuel must be preserved on aging spacecraft?

The output is a comparison of plan branches with quantified tradeoffs, not just
a single activity list.

## Implemented V3 Strategy Slices

The Implemented V3 Strategy Slices section has grown large enough to live in
its own subdirectory. Each sub-file covers one cohesive area of the V3
mission-orchestration implementation.

- [Overview and Strategy API](03_v3_implemented_slices/01_overview_and_strategy_api.md)
- [Core Concepts and Artifacts](03_v3_implemented_slices/02_core_concepts_and_artifacts.md)
- [What-If Event Types](03_v3_implemented_slices/03_what_if_event_types.md)
- [Branch Derivation and Artifact Output](03_v3_implemented_slices/04_branch_derivation_and_artifact_output.md)
- [Urgent Targets, Resource Model, and Candidate Refresh](03_v3_implemented_slices/05_urgent_targets_resource_model_and_refresh.md)
- [Operational Feedback, Approval Policy, Examples, and Limits](03_v3_implemented_slices/06_operational_feedback_and_approval_policy.md)

## Policy-Aware Autonomy

V3 can recommend and prepare operational changes, while Cadence owns approval
boundaries.

Examples:

- auto-generate a recovery plan after missed downlink,
- recommend retasking another spacecraft,
- propose maneuver timing changes,
- stage command-window requests,
- flag high-risk changes for human review,
- auto-approve low-risk replans when policy allows.

The important boundary is policy-aware autonomy, not uncontrolled automation.

## Fleet-Level Resource Allocation

At V3 scale, scheduling becomes fleet-level resource allocation:

- which spacecraft gets which target,
- which downlink gets which station,
- which activity receives scarce power, storage, or contact time,
- which customer or mission objective wins a conflict,
- which degraded spacecraft should be protected.

The planner may eventually behave like an internal mission economy where
activities compete for constrained resources based on priority, urgency, risk,
and value.

## Learning From Operations

V3 should compare plans against outcomes and improve future estimates:

- predicted versus realized contact performance,
- maneuver execution error,
- actual downlink throughput by station, elevation, or provider,
- activity failure rates,
- margins that were too tight,
- spacecraft-specific behavior.

This does not require machine learning as the first step. Calibrated empirical
models and feedback metrics are already valuable.

## Multi-Regime Expansion

V3 may begin expanding beyond the first LEO campaign shape:

- MEO and GEO support,
- cislunar mission phases,
- formation flying,
- rideshare deployment campaigns,
- transfer and phasing strategies,
- heterogeneous fleets.

This expansion should follow a strong LEO operational loop, not precede it.
