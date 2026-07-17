# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema objective-report JSON property-dispatch extraction.

Status:
Published.

Selected slice:
Extract property dispatch for objective-satisfaction and objective-tradeoff
reports from `OrbitalDynamics.Schema` into one internal objective-report
dispatcher.

Why this slice:
The two adjacent clauses duplicate the same contract-sensitive
`ObjectiveReportJsonSchema` predicate and complete eager context, and have
focused optimizer-objective coverage. Optimizer ranking and objective runtime
behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two objective-report contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new objective-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused optimizer-objective contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
The two duplicate facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.ObjectiveReportPropertyDispatch`. The internal
dispatcher owns the allowed contract family, eager context assembly,
contract-sensitive focused predicate/property builder, and common fallback.
All satisfaction/tradeoff rows, model limits, model values, and evaluation
order remain exact. The facade is 9,433 lines; the dispatcher is 31 lines.
Implementation published as `d6ae77c8`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 24 focused optimizer-objective, JSON export, schema export, and export-task
  tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.
- None for this slice.

Last completed slice:
Schema objective-report property dispatch published as `d6ae77c8`:
satisfaction and tradeoff reports now route through one cohesive internal
dispatcher, 24 focused/export tests passed, full regeneration was
byte-identical, and bounded review found no blocker.

Next candidate:
Extract the adjacent ranking-comparison and Pareto-frontier property clauses
into one internal optimizer-report dispatcher. Preserve contract-sensitive
predicates, exact row/winner/model-limit callbacks, stable identity, common
fallback, validators, and exact exports. Leave score-term and resource-filter
summary clauses in the facade.

Blocked:
No.
