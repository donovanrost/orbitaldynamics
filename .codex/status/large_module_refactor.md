# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation source-match callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Point allocation, capacity-pack, and provider-calendar contention
general/cadence source-match callbacks directly at the existing
`Schema.ContactAllocationHandoffContracts` owner. Remove the six facade
delegates. Leave allocation-field validation and its duplicate-evidence
callback unchanged.

Why this slice:
Twelve callback positions forward unchanged through six source-match delegates
to one existing owner. The owner already retains specialized/fallback behavior
and provider source precedence. Excluding allocation-field validation preserves
the facade-owned duplicate-evidence dependency and avoids a broad callback bag.

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
All twelve selected source-match captures point directly to
`ContactAllocationHandoffContracts`, the six facade delegates are gone, and
allocation-field validation still injects
`validate_contact_allocation_duplicate_evidence/3`,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
All allocation, capacity-pack, and provider-calendar contention source-match
callbacks now capture `ContactAllocationHandoffContracts` directly. Six facade
delegates were removed across twelve capture positions, reducing `schema.ex`
from 8,736 to 8,657 lines. Provider source precedence and allocation-field
duplicate-evidence injection remain unchanged.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 42 focused contact-allocation/provider-contention schema contract tests
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
Schema contact-allocation source-match callback ownership cleanup published as
`c6930074`: twelve allocation, capacity-pack, and provider-contention captures
now point directly to their owner while duplicate-evidence injection remains
facade-owned; 182 schema/export tests passed, full export bytes stayed exact,
and bounded review was clean.

Next candidate:
Leave contact-allocation field validation in the facade because moving it would
drag the report-domain callback bag across the boundary. Audit the adjacent
operational-readiness and quality-gate source-match wrappers instead: four pure
delegates appear across fourteen callback positions and already have dedicated
owners.

Blocked:
No.
