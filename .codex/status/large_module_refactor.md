# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation owner routing extraction.

Status:
Completed and pushed.

Selected boundary:
Add a registry-backed `StationReservationValidation.validate_artifact/4` entry
point for the reservation report, review summary, hold summary, and hold
import-readiness summary. Derive requirements from
`StationReservationRegistryContracts` and
`StationReservationHoldRegistryContracts`, route all four direct `Schema`
clauses, and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,803 lines; the other
  targeted public facades are now 164 to 524 lines.
- The four clauses repeat required-field setup and form the exact two registry
  families already operationally owned by `StationReservationValidation`.
- The owner already owns summary model limits; report models are available
  directly from `StationReservationReportJsonSchema`.
- No route needs recursive `Schema` lookup.
- Station-calendar provider, report, and precedence artifacts remain separate
  because they belong to distinct registry/context boundaries.

Implementation:
Added a registry-backed `StationReservationValidation.validate_artifact/4`
entry point plus compact owner-default wrappers, moved report-model resolution
into the existing owner, and routed the four selected direct `Schema` clauses
through it. `schema.ex` moved from 4,803 to 4,795 lines.

Verification:
- Strict focused baseline: 64 tests passed.
- Focused plus adjacent station, validation, communications, candidate-refresh
  replay, campaign-planner source-report, operator-review, contract, and export
  coverage after extraction: 76 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the four intended direct facade routes.
- `mix xref trace` confirmed all four runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, owner-default
  report models and summary model limits, contract routing, validation ordering,
  paths, and station-calendar exclusions remain unchanged.
- Implementation committed and pushed as `5f3c7f1b`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `StationReservationValidation` APIs, validation results, and
checked-in exports remain unchanged.

Last completed slice:
Schema station-reservation owner routing extraction, selected in `c1049e27`
and implemented in `5f3c7f1b`.
`schema.ex` moved from 4,803 to 4,795 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
