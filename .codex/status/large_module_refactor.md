# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity owner completion.

Status:
Completed and pushed.

Selected boundary:
Add a registry-backed `LinkCapacityValidation.validate_summary/3` entry point
for `link_capacity_summary.v1` and route its direct `Schema` clause through the
existing owner. Preserve the existing report and optional-report APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,773 lines; the other
  targeted public facades are now 164 to 524 lines.
- `link_capacity_report.v1` already routes through `LinkCapacityValidation`.
- `link_capacity_summary.v1` is the only other
  `LinkCapacityRegistryContracts` member and repeats registry-required setup in
  the facade.
- `LinkCapacitySummaryContracts` owns all summary-specific validation.
- No route needs recursive `Schema` lookup.
- `relay_data_path_summary.v1` remains out of scope because it belongs to the
  distinct `RelayDataPathRegistryContracts` family.

Implementation:
Added registry-backed `LinkCapacityValidation.validate_summary/3`, shared the
existing registry requirement lookup with report validation, and routed the
summary's direct `Schema` clause through the owner. `schema.ex` moved from
4,773 to 4,771 lines.

Verification:
- Strict focused baseline: 59 tests passed.
- Focused plus adjacent link-capacity, validation, operator-review,
  candidate-refresh replay, campaign-planner source-report, Cadence import,
  contract, and export coverage after extraction: 76 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the report and summary facade calls.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, report/summary
  contract routing, validation ordering, paths, optional-report behavior, and
  the relay-data-path exclusion remain unchanged.
- Implementation committed and pushed as `a5337b46`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `LinkCapacityValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema link-capacity owner completion, selected in `e74cce47` and implemented
in `a5337b46`.
`schema.ex` moved from 4,773 to 4,771 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
