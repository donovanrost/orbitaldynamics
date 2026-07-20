# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity validation routing.

Status:
Completed and pushed.

Selected boundary:
Add a small LinkCapacityValidation owner for registry-required report
validation and optional report shape handling. Route the direct Schema report
consumer and both campaign callback consumers to that owner, and remove the
facade-local optional closure. Keep the 910-line LinkCapacityReportContracts
module focused on artifact-specific validation rather than adding orchestration
to that existing hotspot.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,202 lines; the other
  targeted public facades are now 164 to 524 lines.
- Exact usage finds one direct report validation and two campaign optional
  callbacks behind one facade-local closure.
- LinkCapacityRegistryContracts owns the required-field list and
  LinkCapacityReportContracts owns all artifact-specific validation.
- Optional shape handling requires only PrimitiveValidation.error/2.
- No callback needs recursive Schema lookup or another facade-local validator.
- A separate owner avoids adding context orchestration to the already
  910-line report contract module.

Implementation:
Added LinkCapacityValidation with registry-required report validation and
optional report shape handling. Routed the direct Schema report consumer and
both campaign callback consumers to the owner, removed the facade-local
optional closure, and left LinkCapacityReportContracts unchanged.
`schema.ex` moved from 5,202 to 5,191 lines.

Verification:
- Strict link-capacity/campaign baseline before routing: 51 passed.
- The same strict focused suite after routing: 51 passed.
- Strict full link-capacity, Cadence, campaign, validation, operator-review,
  and candidate-refresh coverage: 92 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one direct and two optional owner routes and
  zero facade-local link-capacity closures.
- `mix xref callers OrbitalDynamics.Schema.LinkCapacityValidation` reports only
  the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,074 files with no warnings.
- Bounded local review confirmed registry requirements, optional error path,
  validation ordering, and issue prepending match the former facade routes.
- Implementation commit `569e3c34` pushed to `main`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public Schema APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema link-capacity validation routing, selected in `1f254ec7` and implemented
in `569e3c34`.
`schema.ex` moved from 5,202 to 5,191 lines.

Next candidate:
Re-evaluate campaign plan/repair callback ownership now that their optional
artifact dependencies route to existing owners.

Blocked:
No.
