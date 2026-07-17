# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optimizer-report JSON property-dispatch extraction.

Status:
Published.

Selected slice:
Extract property dispatch for ranking-comparison and Pareto-frontier reports
from `OrbitalDynamics.Schema` into one internal optimizer-report dispatcher.

Why this slice:
The two adjacent clauses duplicate the same contract-sensitive
`OptimizerReportJsonSchema` predicate and complete lazy context, and have
focused optimizer-objective coverage. Score-term and optimizer runtime behavior
remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two optimizer-report contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new optimizer-report property-dispatch module
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
`OrbitalDynamics.Schema.OptimizerReportPropertyDispatch`. The dispatcher owns
the allowed contract family, lazy context assembly, contract-sensitive focused
predicate/property builder, and common fallback. Ranking/Pareto row, winner,
model-limit, and stable-identity callbacks remain exact. The facade is 9,414
lines; the dispatcher is 32 lines. Implementation published as `3c7967da`.

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
Schema optimizer-report property dispatch published as `3c7967da`: ranking and
Pareto reports now route through one cohesive internal dispatcher, 24
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Extract the four adjacent specialized operational quality-gate summaries
(unavailable-resource, operator-training, schema-validation, and
import-readiness) into one internal dispatcher. Preserve each module/model-limit
pair, shared stable identity, common fallback, validators, and exact exports.
Leave the general operational quality-gate summary and execution-boundary
summary in the facade.

Blocked:
No.
