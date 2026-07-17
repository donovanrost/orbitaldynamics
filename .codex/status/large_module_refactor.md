# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema command-window/maneuver handoff callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point the command-window and maneuver-review handoff callback captures directly
at the existing `Schema.CommandWindowManeuverHandoffContracts` owner. Remove
the four redundant private delegates across the general and
cadence-source-review validation paths.

Why this slice:
All four delegates are pure pass-throughs to one already-extracted internal
module, whose public targets retain their specialized and fallback clauses.
Each family has three general capture sites and one cadence-specific site, so
the eight callback positions form one small, independently reviewable owner
boundary.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
Every callback list directly captures the corresponding public
`CommandWindowManeuverHandoffContracts` validator, the four facade delegates
are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema strategy handoff callback ownership cleanup published as `1118be3d`:
all recommendation/tradeoff, branch, ranking, and Pareto callback captures now
point directly to their existing contract owner; 182 schema/export tests
passed, full export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the command-window/maneuver-review handoff callback family. Both
general/cadence pairs appear to be pure delegates to the existing
`CommandWindowManeuverHandoffContracts` owner; select only after confirming
capture counts, exact targets, and fallback clauses.

Blocked:
No.
