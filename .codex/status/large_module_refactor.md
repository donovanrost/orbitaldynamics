# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-report owner routing extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `ContactReportValidation` APIs, validation results, and checked-in
exports must remain unchanged.

Last completed slice:
Schema contact-allocation owner routing extraction, selected in `efc25373` and
implemented in `6cc22c0b`.
`schema.ex` moved from 4,795 to 4,787 lines.

Next candidate:
Implement and verify the selected contact-report owner routing, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.
