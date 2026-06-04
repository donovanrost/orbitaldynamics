# Level 4: Rolling Operations Planner V2

Feature complete when a prior plan plus realized operations can produce a
repaired remaining-horizon plan with deltas, preservation policy, churn costs,
approval requirements, and degraded-spacecraft handling.

Status: `implemented` as a repair layer over V1 artifacts. It is still `partial`
as an operations planner because candidate refresh is supplied as an explicit
artifact input rather than executed from live branch state, and it does not
simulate resources. When a refresh artifact is supplied, V2 now preserves its
contact/resource rows plus candidate-diff and freshness reports at the repair
boundary.

