# 10. Search and Optimization

Status: **implemented** (with **partial**, **near-term**, **later**, and **out of scope** items below).

## Implemented

### Generators and study scaffolding

- **Core components** — `Search.Grid`, `Search.MonteCarlo`, seeded study manifests, candidate activity generation for V1, greedy timeline ranking, V2 repair, and V3 branch comparison.
- **Capability metadata** — the grid and Monte Carlo generators declare their ordering, reproducibility, and known-limit capability metadata.

### V1 campaign artifacts: `optimizer_contract.v1`

V1 campaign artifacts emit `optimizer_contract.v1` records that declare, behind the selected ranked timeline:

- the greedy selector,
- deterministic ordering,
- selected activity IDs,
- candidate lineage fields,
- score-term keys,
- known limits, and
- policy/constraint inputs.

### Monte Carlo artifacts: `monte_carlo_reproducibility_report.v1`

Monte Carlo result artifacts emit `monte_carlo_reproducibility_report.v1` records with:

- seeded generator settings,
- generated scenario IDs,
- position/velocity sigma triplets,
- deterministic RNG assumptions, and
- known limits.

Executable validation checks these against `OrbitalDynamics.Search.MonteCarlo.capabilities/0`.

### V3 strategy artifacts: `branch_comparison_report.v1`

V3 strategy artifacts emit `branch_comparison_report.v1` rows that flatten, for what-if comparison:

- branch rank,
- score deltas,
- approval status,
- risk counts,
- risk types,
- high-risk types,
- approval burden,
- repair deltas,
- score terms,
- priority-commitment counts,
- downlink-completion ratio/data-volume evidence,
- observed target count,
- revisit count,
- collection-latency satisfaction,
- resource margins,
- availability,
- resource score adjustment,
- fuel-preservation mode,
- resource risk types,
- branch resource-projection overflow/shortfall,
- first resource-pressure activity,
- reduced-capacity contact-allocation pack status/group summaries,
- branch-event station/calendar/provider/reservation summaries,
- V2 repair score-term summaries, and
- repaired link-capacity throughput summaries plus repaired constraint counts/statuses.

### Ranking comparison

- **Functions** — `Optimizer.compare_rankings/3` and `OrbitalDynamics.compare_scenario_rankings/3` compare two ranked scenario lists with deterministic rank/value deltas and winner-change metadata for search and what-if review.
- **`ranking_comparison_report.v1` contract** — provides the same comparison as an executable/exported artifact contract, **without invoking an external solver**. It uses executable integer validation for left/right ranks and signed rank deltas while objective values remain numeric, plus report-level `model_limits` validation against `Optimizer.ranking_comparison_model_limits/0`. Clean numeric-string ranking values are normalized before report emission, while malformed numeric strings remain missing numeric evidence.
- **Operator review and import gates** — ranking comparison reports can be normalized into `operator_review_package.v1` `ranking_comparison_review` rows for persisted import-gate review, and Cadence import manifests preserve those rows as typed `review_ranking_comparison` gates with left/right rank and value evidence.
- **Strategy tradeoff gates** — standalone branch-comparison rows likewise preserve source tradeoff and branch objective/feedback/resource risk evidence plus repaired score/link-capacity evidence through typed `review_strategy_tradeoff` import gates, and full-strategy direct branch import rows promote the same branch evidence for selected/rejected strategy branch review.
- **Result-set comparisons** — result-set comparisons emit `ranking_comparison_report.v1` when both saved study artifacts carry compatible declared rankings, with clean numeric-string trajectory metrics, maneuver counts, event boundaries, and ranking values normalized before summaries, ranks, and boundary deltas are computed.
- **Embedded in V3 strategy artifacts** — V3 strategy artifacts embed a ranking comparison report for normalized branch order versus score-ranked branch order, which is also normalized into the strategy `operator_review_package.v1`.

### Pareto frontier reporting

- **Functions** — `Optimizer.pareto_frontier_report/2` and `OrbitalDynamics.pareto_frontier_report/2` emit a schema-validated `pareto_frontier_report.v1` dominance summary over supplied objective vectors. It records objective directions, frontier/dominated IDs, and dominance links **without generating alternatives or invoking a solver**, with report-level `model_limits` validation against `Optimizer.pareto_frontier_model_limits/0` and clean numeric-string objective vector values normalized before dominance checks.
- **Embedded in V3 strategy artifacts** — V3 strategy artifacts embed the same Pareto frontier contract over branch comparison objective vectors, including repaired constraint warning/fail counts as minimization objectives. Both standalone and embedded reports normalize to `pareto_frontier_review` operator-review/import rows, with typed `review_pareto_frontier` Cadence gates preserving objective vectors and dominance context.

### Bounded explainable local search

- **Neighborhood generation** — `Search.Local.neighborhood/2` generates the
  seed plus deterministically ordered single-axis decrease/increase moves over
  named numeric parameters. Optional box bounds reject out-of-range moves with
  explicit reasons, and `max_alternatives` deterministically truncates the
  feasible set. At most 32 parameters may be stepped; the default bound is 17
  alternatives and the hard limit is 65 (seed plus two moves per parameter).
- **Generation plus evaluation** — `Optimizer.explainable_local_search/3` and
  `OrbitalDynamics.explainable_local_search/3` evaluate the generated set from
  a caller-supplied non-empty numeric score-term map. They select by summed
  score, then generation order, then alternative ID; the result retains seed
  delta, every parameter move, score contribution, rank, selection reason,
  rejected move, ordering rule, and model limit. An opt-in exact `hard` mode
  first evaluates semantic resource-trace evidence and link-budget
  completion/shortfall evidence against a separate trusted composition registry
  of expected candidate parameter and source-artifact identities; only eligible
  alternatives enter that deterministic ranking.
- **Reproducibility boundary** — no RNG or external solver is used. Identical
  inputs produce identical generation and ranking when the caller-supplied
  score-term function is pure and deterministic.
- **Model limits** — this is one numeric, single-axis, single-step
  neighborhood with box bounds only. It performs no iterative convergence,
  coupled moves, broad campaign constraint evaluation, source-model
  propagation, or calibration from operational outcomes. Without explicit hard
  mode it performs no feasibility evaluation beyond box bounds. Hard mode is
  limited to one semantically validated resource-state threshold and one
  validated downlink threshold per candidate; it is not wired into V1, V2, or
  V3 planner execution and does not repair ranking results. Its caller-supplied
  registry is an immutable routing snapshot, not authentication or signature
  verification; coordinated malicious replacement of registry and artifacts is
  outside Level 5 and Domain 22.

## Partial

- Candidate generation can be refreshed from planning-state artifacts, including per-branch V3 refresh inputs, but optimizers remain transparent and simple.
- Ranking comparison and Pareto reporting still operate only on supplied rows;
  the additive local-search path generates and evaluates a small alternative
  set but is not wired into V1, V2, or V3 planner execution.

## Near-term

- Broaden comparison reports across richer branch generations, saved result-set comparisons, and operator workflows that need persisted dominance context beyond branch-local objective vectors.
- Add schema-versioned persistence for local-search evidence only when a stable
  operator or interchange consumer requires it.

## Later

- Iterative and coupled-move local search, MILP/CP-SAT, stochastic search,
  evolutionary methods, dynamic programming, and external optimizer adapters.

## Out of scope

- Optimizer choices that cannot explain why one operational plan beat another.
