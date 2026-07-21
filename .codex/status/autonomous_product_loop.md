# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply selected station-calendar pressure directly to V2 repair scoring.

Status:
Implemented and verified; publish pending.

Why this slice:
V2 overlays repair-time station calendars onto source candidates and preserves
`station_calendar_report.v1` in review/import evidence, but selected calendar
pressure is absent from repair scoring. The report is source-candidate scoped,
so simply counting every affected row would incorrectly penalize a repair for
unselected alternatives. The live selected activity IDs provide the exact safe
intersection.

Level 6 pillar:
Fleet-level contact/resource behavior plus reproducible, explainable V2/V3
branch scores.

Behavior/evidence added:
- `RepairScoreTerms` now intersects `station_calendar_report.v1` affected contact
  IDs with the repaired selected activity IDs.
- Matching rows reuse the existing V3 station-calendar classifier, so only
  reserved, unavailable, or reduced-capacity pressure contributes one normalized
  `risk_weight` unit through `station_calendar_pressure_penalty`.
- Selected reduced-capacity and reserved contacts expose the conditional term;
  an affected but unselected planned contact does not change score or report.
- Repair score and `score_term_report.v1` totals remain aligned and schema-valid;
  calendar annotation and review/import handoffs are unchanged.
- Updated the V2 capability/product docs and roadmap with exact selected-scope
  semantics and artifact-only limits.

Verification:
- Focused station-calendar and link-capacity repair suites: 7 passed.
- All V2 repair tests: 52 passed.
- Full campaign-planner area: 742 passed.
- Full `mix test --timeout 120000`: 3,485 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, formatting, and diff checks: pass.

Parent review:
Complete. The parent inspected selected-ID intersection, shared V3 pressure
classification, reduced-capacity and reservation behavior, unselected-contact
omission, duplicate affected-row semantics, numeric-string risk-weight handling,
score/report agreement, schemas, docs, and unchanged review/import routing.
Review added an explicit reserved-selected score assertion; no code must-fix
findings remain. Runtime policy disallows subagent delegation, so the parent
performed review and publish prep.

Previous published slice:
- `26893419` Score repair link capacity shortfalls (`3485 passed`).

Remaining maturity gaps:
- Continue selected resource pressure in repair scoring where live evidence
  remains explanation-only.
- Continue calibrated realized-feedback depth and deeper numerical/backend and
  resource-model maturity separately.

Blocked:
Not blocked. Runtime policy disallows subagent delegation, so the parent will
perform bounded review and publish handoff.
