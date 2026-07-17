# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema command-window/maneuver handoff callback ownership cleanup.

Status:
Completed and published.

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

Outcome:
All command-window and maneuver-review callback lists now capture the existing
`CommandWindowManeuverHandoffContracts` validators directly. Four private
one-hop delegates were removed, reducing `schema.ex` from 8,990 to 8,942 lines
without changing callback keys, order, fallback behavior, validation results,
or checked-in schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 61 focused command-window/maneuver-referencing schema contract tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

Last completed slice:
Schema command-window/maneuver handoff callback ownership cleanup published as
`2c91d4e8`: both general/cadence callback pairs now point directly to their
existing contract owner; 182 schema/export tests passed, full export bytes
stayed exact, and bounded review was clean.

Next candidate:
Audit the contact-contention handoff callback family. Its general/cadence
callbacks target the existing `ContactContentionHandoffContracts` owner, but
the facade also has a cadence fallback clause; select only after proving that
the owner retains the same fallback and all four general/one cadence capture
positions can move without changing issue order.

Blocked:
No.
