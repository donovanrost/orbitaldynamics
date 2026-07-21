# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply selected link-capacity shortfall directly to V2 repair scoring.

Status:
Implemented and verified; publish pending.

Why this slice:
The live V2 repair path already computes `link_capacity_report.v1` from selected
repaired activities and uses it in constraints, branch comparison, recommendation
explanations, and review/import artifacts. It currently computes the report only
after repair scoring, so a selected downlink shortfall cannot affect the repair
score or appear in `score_term_report.v1`. V3 source-replay branches already
have a dedicated link-capacity pressure term, leaving V2 inconsistent.

Level 6 pillar:
Fleet-level contact/resource behavior plus reproducible, explainable V2/V3
branch scores.

Behavior/evidence added:
- V2 now computes its repaired-activity `link_capacity_report.v1` before repair
  scoring and passes that exact report into `RepairScoreTerms`.
- Positive selected shortfall contributes one normalized `risk_weight` unit as
  `link_capacity_pressure_penalty`; satisfied or undeclared demand omits the
  conditional term.
- The repair score and `score_term_report.v1` expose the same penalty and remain
  schema-valid; numeric-string risk weights normalize through the existing
  scoring policy boundary.
- Updated the V2 capability/product docs and roadmap to state the planner-visible
  behavior and preserve the artifact-only/no-provider-write limit.

Verification:
- Focused repair/link-capacity/source-report/constraint suites: 16 passed.
- All V2 repair tests: 52 passed.
- Full campaign-planner area: 742 passed.
- Full `mix test --timeout 120000`: 3,485 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, formatting, and diff checks: pass.

Parent review:
Complete. The parent inspected link-capacity computation order, the exact
positive-shortfall predicate, numeric-string risk-weight normalization,
satisfied/undeclared omission behavior, score/report total agreement, V3 branch
compatibility, schemas, and public docs. Review corrected one doc phrase that
called the repaired link report a source-pressure term; no code or test must-fix
findings remain. Runtime policy disallows subagent delegation, so the parent
performed review and publish prep.

Previous published slice:
- `bf1f673b` Add quality gate selection challenge (`3484 passed`).

Remaining maturity gaps:
- Continue selected station-calendar/resource pressure in repair scoring where
  live evidence remains explanation-only.
- Continue calibrated realized-feedback depth and deeper numerical/backend and
  resource-model maturity separately.

Blocked:
Not blocked. Runtime policy disallows subagent delegation, so the parent will
perform bounded review and publish handoff.
