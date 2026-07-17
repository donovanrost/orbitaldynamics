# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema specialized quality-gate-summary JSON property-dispatch extraction.

Status:
Completed and published.

Selected slice:
Extract property dispatch for operational quality-gate unavailable-resource,
operator-training, schema-validation, and import-readiness summaries from
`OrbitalDynamics.Schema` into one internal specialized quality-gate dispatcher.

Why this slice:
The four adjacent clauses share the same model-limit/stable-identity dependency
shape, retain explicit module/model-limit pairs, and have focused operational
readiness coverage. The general quality-gate summary, execution boundary, and
runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the four specialized quality-gate contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new specialized quality-gate-summary property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused operational/readiness contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
The four specialized quality-gate clauses now route through
`SpecializedQualityGateSummaryPropertyDispatch`. The dispatcher owns the
literal contract family, exact JSON-schema-module/model-limit pairings, focused
field routing, and default fallback. `OrbitalDynamics.Schema` remains the public
facade and supplies only the existing private dependencies as callbacks.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 33 focused operational/readiness and schema/export tests
- full checked-in schema export; aggregate bundle digest remained
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- new-file diff hygiene
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None. Full export regeneration was byte-identical.

Files changed:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/specialized_quality_gate_summary_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Last completed slice:
Schema specialized quality-gate-summary property dispatch published as
`89329531`: unavailable-resource, operator-training, schema-validation, and
import-readiness summaries now route through one cohesive internal dispatcher,
33 focused/export tests passed, full regeneration was byte-identical, and
bounded review found no finding.

Next candidate:
Audit the six general operational/readiness summary/report property clauses
around the specialized dispatcher. Select them only if their shared capability,
gate, model-limit, row/evidence, and stable-identity dependency shape supports
one explicit dispatcher without obscuring the distinct contracts.

Blocked:
No.
