# Planning, Optimization, and Onboard Autonomy

## Planning and Optimization

The mature planner should support richer search only after resource and
subsystem constraints are concrete.

Feature areas:

- feasible candidate generation
- constraint satisfaction
- repair neighborhoods
- local search
- MILP or CP-SAT adapter contracts
- stochastic or evolutionary search
- branch-tree simulation
- robust planning under uncertainty
- multi-objective optimization
- Pareto explanation
- schedule churn minimization
- approval-burden minimization

Optimizers must preserve explainability. Operators need to know why one plan
won and which constraints or assumptions drove the decision.

## Onboard Autonomy Boundary

Some spacecraft can replan, schedule, or react autonomously onboard. The ground
planner must make that boundary explicit.

Feature areas:

- ground planner responsibility
- onboard planner responsibility
- autonomy envelopes
- onboard constraint uploads
- autonomous event response assumptions
- command delegation limits
- autonomous activity cancellation rules
- onboard resource-protection rules
- ground-approved objective envelopes
- reconciliation after onboard replanning
- telemetry required to confirm autonomous outcomes

Planning artifacts should state what the ground plan assumes the spacecraft may
change autonomously and which activities remain ground-authoritative.

## Automation Guardrails

Future planner automation needs explicit guardrails.

Feature areas:

- allowed automation level
- human-confirmation requirements
- no-autonomous-command boundary
- confidence thresholds
- model-readiness thresholds
- quality-gate requirements
- planner self-checks
- rollback or recovery plan
- generated recommendation audit trail
- blocked automation conditions

Automation guardrails should prevent a useful analysis planner from being
mistaken for an autonomous operations authority.

