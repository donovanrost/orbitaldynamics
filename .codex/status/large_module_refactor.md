# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-report owner routing extraction.

Status:
Completed and pushed.

Selected boundary:
Add owner-default entry points to `ContactReportValidation` for contact filter
report and contention report, resolution report, and resolution summary.
Preserve direct contract routing for the two report artifacts; derive required
fields for filter report and resolution summary from their registry modules.
Move resolution-summary model-limit and policy-callback defaults into the owner,
route all four direct `Schema` clauses, and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,787 lines; the other
  targeted public facades are now 164 to 524 lines.
- `ContactReportValidation` already owns optional filter and contention report
  routing and the filter report callback.
- `ContactFilterRegistryContracts` and
  `ContactContentionRegistryContracts` own selected required fields.
- Resolution-summary model limits are available from
  `ContactContentionCapabilityContext`, and its policy callback is contract
  owned; no facade-only context is required.
- Direct contention report and resolution-report routing must remain free of a
  newly introduced facade-level required-field pass.
- No route needs recursive `Schema` lookup.

Implementation:
Added four owner-default artifact entry points to `ContactReportValidation`,
moved resolution-summary model-limit and policy-callback wiring into the owner,
and routed all selected direct `Schema` clauses through it. `schema.ex` moved
from 4,787 to 4,773 lines.

Verification:
- Strict focused baseline: 97 tests passed.
- Focused plus adjacent contact-report, validation, operator-review,
  candidate-refresh replay, campaign-planner source-report, contract, and
  export coverage after extraction: 121 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the four intended direct facade routes.
- `mix xref trace` confirmed all four runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed registry-owned required fields for filter and
  resolution summary, direct contract routing for both contention reports,
  owner-default model limits and callback, validation ordering, and paths remain
  unchanged.
- Implementation committed and pushed as `902d27d5`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `ContactReportValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema contact-report owner routing extraction, selected in `7781b44c` and
implemented in `902d27d5`.
`schema.ex` moved from 4,787 to 4,773 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
