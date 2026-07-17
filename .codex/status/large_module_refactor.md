# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational readiness gate-summary JSON property-dispatch extraction.

Status:
Completed and published.

Selected slice:
Extract property dispatch for operational import-eligibility, readiness-gate,
and execution-boundary summaries from `OrbitalDynamics.Schema` into one
internal operational readiness gate-summary dispatcher.

Why this slice:
The three summary contracts share the operational-readiness capability,
operational gate schema, and contract-specific model-limit dependency core.
Readiness-gate adds stable identity and execution-boundary adds string-array
schema, but both remain explicit contract dependencies. General quality-gate
and report contracts have separate row/evidence responsibilities and stay out
of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three operational gate-summary contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new operational readiness gate-summary property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused operational contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three facade clauses become one guarded delegate to the internal gate
summary dispatcher; runtime schemas, validators, bundle ordering, and
checked-in exports remain exact; focused and export tests pass; and bounded
review finds no blocker.

Outcome:
The three operational readiness gate-summary clauses now route through
`OperationalReadinessGateSummaryPropertyDispatch`. The dispatcher owns the
literal contract family, exact JSON-schema-module/dependency pairings, focused
field routing, and default fallback. `OrbitalDynamics.Schema` remains the public
facade and supplies only its existing private dependencies as callbacks.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 30 focused operational and schema/export tests
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
- `lib/orbital_dynamics/schema/operational_readiness_gate_summary_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Last completed slice:
Schema operational readiness gate-summary property dispatch published as
`ae307679`: import-eligibility, readiness-gate, and execution-boundary summaries
now route through one cohesive internal dispatcher, 30 focused/export tests
passed, full regeneration was byte-identical, and bounded review found no
finding.

Next candidate:
Audit the general operational quality-gate summary and quality-gate report as a
two-contract family: both use the operational-readiness capability,
quality-gate row schema, stable identity, and contract-specific model limits.
Keep the operational readiness report separate because it owns gate/evidence
schema rather than quality-gate rows.

Blocked:
No.
