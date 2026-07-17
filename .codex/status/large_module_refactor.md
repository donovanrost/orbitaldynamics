# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity JSON property-dispatch extraction.

Status:
Published.

Selected slice:
Extract property dispatch for link-capacity report and link-capacity summary
from `OrbitalDynamics.Schema` into one internal link-capacity dispatcher.

Why this slice:
The two adjacent clauses share link-capacity model limits and six common schema
helpers while retaining explicit report/summary-only dependencies and focused
communications contract coverage. Station-provider, relay-data-path, and
link-capacity runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two link-capacity contracts, bundle ordering, and
checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new link-capacity property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused communications and communications-report fixture tests
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
The two facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.LinkCapacityPropertyDispatch`. The internal dispatcher
preserves contract-to-module routing, focused-field selection, distinct report
and summary assumption callbacks, report-only row/throughput-derivation
callbacks, summary-only numeric-map callbacks, shared model limits/common
schema helpers, and the fallback. The facade is 9,579 lines; the new dispatcher
is 54 lines. Implementation published as `163560ab`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 34 focused communications, communications-report, JSON export, schema export,
  and export-task tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.
- None for this slice.

Last completed slice:
Schema link-capacity property dispatch published as `163560ab`: report and
summary now route through one cohesive internal dispatcher, 34 focused/export
tests passed, full regeneration was byte-identical, and bounded review found no
blocker.

Next candidate:
Extract the five adjacent contact-allocation summary property clauses (base,
reservation-conflict, station-pressure, capacity-pack, and provider-reservation
request) into one internal summary dispatcher. Preserve each schema contract
and assumptions callback, shared model limits/stable identity/row callback,
capacity-pack-only group callback, fallback behavior, validators, and exact
exports. Leave the preceding contact-allocation report in the facade.

Blocked:
No.
