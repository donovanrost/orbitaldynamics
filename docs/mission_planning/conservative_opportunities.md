# Conservative scheduling opportunities

Mission analysis can now use the shared event search to build opportunities from
named mission constraints. It intersects their known condition windows, removes
numerical boundary bands and unknown regions, applies explicit mission timing
margins, and feeds the resulting windows into the existing scheduler. The core
runner contains no Earth, target, illumination or imaging geometry.

“Conservative” describes boundary placement relative to the supplied functions,
state source and search policy. It does not establish continuous feasibility or
bound physical trajectory, timing, atmosphere or spacecraft uncertainty.

## Run the Reflect-like example

```sh
MIX_ENV=test mix orbital_dynamics.mission.attitude \
  --study studies/illumination_opportunities.json \
  --output-dir tmp/illumination_opportunities
```

This example extends the existing synthetic solar/attitude/battery study. It uses
a 2 s maximum event check step, 0.01 s solver tolerance, 64 iterations and 50,000
combined state/function evaluations per asset/request pair. Mission margins are
0.5 s at each end. These illustrative margins are not estimates of Reflect
Orbital hardware or operations requirements.

The north request schedules at approximately +60.51 through +80.51 s after the
reference epoch. Both requests have a retained physical opportunity; the primary
request is rejected by the bounded attitude/path start search. The complete
selected timeline, terminal motion and idle periods still pass the configured
battery replay. This is an analysis example, not an operations plan.

The physical-window entry is limited by initially unavailable tracking evidence.
The primary window's exit is limited by minimum elevation; the north window ends
at the request/coverage clip. The report names these limits and carries the same
window evidence into activities and selection decisions. The initial tracking gap
comes from starting the request at the ephemeris start without a full lookback.
Actual pre-request state coverage can supply that missing evidence; the runner
does not extrapolate it.

History-dependent attitude transitions and resources remain later scheduling
checks. Battery-state evolution is not assumed to be a state-only event function.

## Numerical bounds and mission margins

For an opening event with numerical root bracket `[a,b]`, use `b + tolerance`.
For a closing event use `a - tolerance`. The extra inward solver tolerance keeps
open/strict boundaries and numerical equality out of an accepted window. The
report records the original estimate, bracket, inward endpoint, requested guard
and realized numerical trim separately.

An estimated boundary must target an event-function zero. A narrow bracket for
a stationary near-zero candidate is not accepted as a bound on a zero. Bounds
that cannot move strictly inward at the absolute epoch's floating-point
resolution are removed, rather than silently rounding the guard away.

Each constraint's windows are intersected by an ordered linear sweep. Every
reported unknown span is independently subtracted, even if an upstream window
incorrectly overlaps it. Event bands for strict constraints are excluded too,
including interior contacts, so equality cannot silently join two eligible
pieces. Gaps are never merged into an activity window.

Only after intersection and exclusion does the runner add `entry_margin_s` to
the opening and subtract `exit_margin_s` from the closing, once per resulting
window. A margin below epoch resolution, an empty interval, or insufficient
remaining duration is retained as a rejection with a named reason. The seconds
of mission margin are distinct from numerical bracket uncertainty and solver
guards. They are caller-declared assumptions, not automatically derived
uncertainty estimates.

## Complete-model checks and budgets

Each pair prepares one opaque model session, reused by all evaluations and the
scheduler. Every scalar callback is wrapped with a complete model evaluation at
the same state and fixed lookback. The wrapper checks that its sign and strictness
agree with the corresponding named model check. Missing checks, inconsistent
scalars or wrong strictness declarations are analysis errors.

All cached complete-model observations are retained, including states evaluated
only during root refinement or midpoint checks. Every candidate is audited
against those observations. A discovered interior failure rejects the candidate,
even when the coarse scan and both endpoints pass. Repeated observations are
not deduplicated in a way that could hide a contradiction.

Both conservative window endpoints are checked against the complete model before
scheduling. Search, nested model/scalar callbacks, source/lookback queries and
these candidate endpoint checks share one per-pair evaluation allowance. The
report separates search counts, endpoint counts and the combined total. Errors
and exhausted budgets abort analysis and restore the per-search cache context.
Selected activity endpoints are checked again by the existing planning runner;
those checks retain their existing separate accounting.

A partial search can retain windows entirely outside every observed unknown
region. Its status is `partial_under_search_policy`, with the underlying search's
unknown intervals preserved. This means known candidate windows survived; it
makes no claim that discovery or coverage was complete. Unknown margins and
prerequisites do not become zero cost, zero power or assumed eligibility.

## Generic model interface

Pass an `Opportunity.Policy` through `MissionAnalysis.run/4`:

```elixir
policy = OrbitalDynamics.MissionAnalysis.Opportunity.Policy.new!(
  max_check_step_s: 2,
  time_tolerance_s: 0.01,
  max_iterations: 64,
  max_evaluations: 50_000,
  entry_margin_s: 0.5,
  exit_margin_s: 0.5
)

# Include opportunity_search: policy alongside the existing analysis options.
```

The existing explicit `window_refinement` policy supplies the checked runtime
state callback and fixed tracking lookback. With opportunity search enabled,
its legacy transition-refinement algorithm is not used. The source is bounded
by the asset's declared trajectory coverage and must return states at the exact
requested epoch in the same frame and scale. No state interpolation or
extrapolation is implicitly added by the opportunity layer.

A model opts in through `opportunity_functions(session, source, lookback_s)`,
returning `{:ok, functions}`. There must be one named condition function per model
check, at most 31, with unique IDs and no direction filter. `mission-evaluation`
is reserved for the complete-model evaluator. Functions declare their units,
value tolerance and inequality; their scalar values must be continuous on their
known domain. Stateful side effects, hidden time dependence and nested searches
are unsupported.

The common adapter consumes an existing model's signed headroom checks:

```elixir
def opportunity_functions(session, source, lookback_s) do
  specs = [
    {"minimum_elevation", "deg", 1.0e-9},
    {"target_dark_enough", "deg", 1.0e-9},
    {"strict_keepout", "deg", 1.0e-9, true}
  ]

  {:ok,
   OrbitalDynamics.MissionAnalysis.Opportunity.Functions.from_evaluation(
     __MODULE__, session, source, lookback_s, specs
   )}
end
```

The example assumes those are exactly the model's three checks. Numeric checks
carry sign-normalized headroom, units and comparison metadata from
`Evaluation.new!/2`. The fourth tuple element marks a strict constraint and must
match `margin_comparison: "strict_min"`. Numeric null margins stay unknown.
A boolean prerequisite can use unit `"1"`; it is known only when true, and false
becomes an unavailable prerequisite rather than a fictitious continuous root.
Explicit geometric overrides can supply continuous margins for boolean geometry.

Illumination and imaging implement this interface using their existing checks.
Illumination supplies continuous cylindrical-shadow and specular-definition
margins. Its switched-off irradiance branch in shadow is treated as outside that
scalar's known domain, with the separate sunlight constraint governing the
boundary. This may conservatively lose time around a branch/coverage edge; the
runner does not pretend a discontinuous power switch has a geometric zero.

Models without the callback report
`model_opportunity_constraints_unavailable` when this policy is requested. They
do not silently fall back to sampled opportunities. Existing studies without
`opportunity_search` retain their existing analysis path.

The reference JSON adapter accepts an `opportunity_search` object with the six
policy fields shown above. It only chooses the existing trusted mission models;
JSON input cannot load a model module.

## Evidence and decision tracing

`analyses[].opportunity_evidence` contains per-constraint condition windows,
removed numerical windows, unknown/open-contact exclusions, intersection and
margin decisions, limiting contributors, full-model endpoint checks, evaluation
counts and the shared event-search report. Cached complete-model observations
include both successful and failing refinement witnesses.

`opportunities[].window_evidence` identifies the exact conservative window sent
to scheduling. Activities and selection decisions retain it as
`opportunity_evidence`. The Markdown report separates window acceptance from
attitude, transition, terminal, path and battery decisions. Sample/check counts
include refinement and endpoint observations; they are not time-weighted
probabilities or estimates of the fraction of a pass that is usable.

Finite scanning can miss narrow events and unobserved extrema or grazing
contacts. Agreement at all tested states is not a continuous-time proof. Mission
margins are not a substitute for future mission-specific uncertainty models or
independent hardware/model validation.

## Verification

The full fast-suite run passed all 5,263 tests (1,146 integration/exhaustive checks
excluded). After the final callback/strictness/zero-target safeguards, all 48
focused opportunity and event-search tests passed. Two end-to-end example tests
cover scheduling with attitude/battery replay and oversized timing-margin
rejection. The frozen numerical mission baseline also passed. Independent review
found no remaining blocker; full integration/exhaustive suites were not run.

Regressions cover bracket-side composition, single margin application, source
and margin unknowns, strict interior contacts, unproven stationary boundaries,
floating-point resolution, callback errors, total budget exhaustion including
endpoint probes, complete declaration coverage, custom scalar/sign/strictness
mismatches, and an interior failure found only by another constraint's refinement.
The same runner also schedules an imaging example on an explicit non-Earth scene.

The cached-observation export changes the executable EventSearch/Context identity.
The curated candidate-refresh artifact report was regenerated with only its
policy fingerprint and dependent refresh ID changed. Physical reference values,
tolerances and original frozen external-reference bundles were unchanged.
