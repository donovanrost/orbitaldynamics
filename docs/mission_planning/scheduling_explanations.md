# Request scheduling evidence

A request left unfulfilled is not necessarily impossible. Its generated windows,
placement grid, current neighbors, subsystem checks and search limits each affect
the outcome. The planner now records compact per-request outcomes for every
completed search trial, including rejected trials. The existing full
`selection_decisions` describe the returned incumbent, not every trial.

## Explain a saved request without replanning

```sh
MIX_ENV=test mix orbital_dynamics.mission.explain \
  --snapshot tmp/plan_revision_urgent_explained/revised_snapshot.json \
  --request urgent-illumination --output-dir tmp/urgent_explanation
```

This checks snapshot identity, then writes `README.md` and `explanation.json` in
fresh output files. It does not call a physical model or rerun the scheduler.
Historical snapshots can be inspected, but missing trial outcomes and missing
neighbor information cannot be reconstructed. They are never silently inferred.

To capture new trial evidence, run the baseline/revision commands in
[plan_revisions.md](plan_revisions.md), using fresh output directories. Reports
also include `requests[].scheduling_summary`; revision reviews surface these
summaries beside unfulfilled requests.

## What the evidence means

- Generation: per-spacecraft analysis status, failed sampled checks, conservative
  constraint-search coverage, excluded unknown intervals and rejected-window reasons.
- Placement: tested starts, first rejection reason at each start, transition-time
  margins, conflicting activities and preceding/following activity identities.
  A protected conflict is labeled with its exact protected placement.
- Subsystems: failing path rule/check or resource model/check, sampled epoch,
  status and available margin. Different checked cadences may report different
  issue epochs. These are observations, not independent failure counts.
- Unknowns and caps: a truncated placement search, unknown feasibility and explicit
  evaluation-limit reasons remain separate from constraint violations. Fatal
  evaluation-budget errors abort planning; revision reviews label that category
  and do not manufacture a usable plan or an infeasibility claim.
- Search: trial limit versus exhausted proposal neighborhood, request selections
  within each trial, and whether that trial was accepted. A request selected only
  in a rejected trial is still unfulfilled in the returned incumbent.

`configured_grid_exhausted` means all configured candidate starts were attempted
for that opportunity in that trial timeline. It says nothing about starts between
grid points or other timelines. Checks can stop at their first failure; the
absence of another failure does not establish that later checks passed. Neighbor
identities provide context, not proof that removing one will make a request fit.

These summaries add evidence without changing placement order, feasibility
policies, search proposals or acceptance rules. They establish no continuous
feasibility, global optimality, operational approval or command authority.

## Known-answer replacement case

A fixed-time one-spacecraft case has a committed service at 20–30 s (value 5)
and tentative work at 80–90 s (value 10). Adding urgent work for 80–90 s (value 20)
yields the exact commitment plus urgent work: value 25 instead of 15. The
independent finite enumeration uses scalar maneuver timing and ideal battery
arithmetic. It agrees with production attitude/path/resource evaluation for this
declared case. It is not an orbital-model validation.

The rejected-trial test separately demonstrates why retention policy matters:
a maneuver-gap trial serves two requests for greater value, but `all_served`
retention refuses to drop the incumbent request. The explanation preserves both
the candidate selections and the controller's rejection reason.

The orbital urgent-request observation is recorded in
[scheduling_explanation_observation.json](scheduling_explanation_observation.json).

Across all four evaluated orbital trials, the urgent request had the same 24
rejected starts: one overlap with protected `early-1`, seven incoming-transition
timing failures, and sixteen sampled `limb_axis` path violations. Its placement
grid was not truncated and none of its assessments was unknown. The outer search
still reached its four-trial cap. This supports the specific tested-start
explanation; it does not prove there is no feasible intervening start or alternate
sequence. No scheduling defect was identified by this investigation, so ordering
and acceptance rules were left unchanged.

The rerun produced identical activities, opportunity analyses, attitude/path/
horizon/resource evidence, balances, trial decisions and model-evaluation counts.
The differences are the added diagnostic evidence. This is a deterministic
regression comparison, not a timing benchmark.
