# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Rank V2 replacements with exact contact-intent pressure.

Status:
Complete; ready to publish.

Selection evidence:
- Final V2 scoring now applies exact selected contact-intent pressure, but
  `RepairReplacementSelection` still ranks viable alternatives without it.
- A higher-value pressured replacement can therefore be selected before the same
  evidence lowers the final repair objective, creating selection/score
  misalignment.
- Repair execution already builds exact candidate-ID pressure context for
  station-calendar and contact-allocation evidence, providing the bounded
  pattern for contact-intent identities.
- The shared normalized V3 contact-intent identity set provides exact status and
  contact ID tuples; no aggregate evidence needs to affect ranking.

Intended behavior:
- Build a deterministic candidate-ID to sorted pressure-status map from validated
  candidate-refresh contact intents through the shared V3 identity-set path.
- Apply one normalized `risk_weight` unit to each viable replacement candidate
  with exact downlink contact-intent pressure.
- Emit numeric `contact_intent_pressure_penalty` and optional nonempty sorted
  known-status evidence on current replacement-ranking rows; accept older V2
  rows without the penalty and default it to zero in contract arithmetic.
- Include the penalty in ranking arithmetic and runtime/JSON Schema validation;
  require status evidence whenever the penalty is nonzero.
- Preserve semantic candidate-diff priority, deterministic tie-breaking, and the
  final-score one-unit-per-unique-contact calibration.
- Keep nominal, unrelated, review-only, non-downlink, duplicate, malformed, and
  zero-weight pressure from creating unexplained ranking effects.
- Add selection-flip, neutral, zero-weight, arithmetic/evidence, schema-export,
  and compatibility coverage and update V2/resource/roadmap documentation.

Level 6 pillar advanced:
Candidate-specific communications pressure aligned between repair selection and
explainable final scoring.

Previous published slice:
- `955e7199` Score V2 contact intent pressure (`3706 passed`).

Likely files:
- repair execution and replacement-selection modules
- V2 replacement-ranking runtime and JSON Schema contracts
- replacement ranking and contact-intent repair tests
- generated campaign-repair schema/bundle plus V2/resource/roadmap docs

Verification:
- Focused ranking/source-handoff contracts: `16 passed`.
- Repair-path suite: `72 passed`.
- Campaign-repair schema fixtures: `11 passed`.
- Schema suite plus schema-lint task tests: `389 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3709 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Full schema export changed only `campaign_repair.v2.schema.json` and the
  aggregate schema bundle.

Review:
- Exact identities are downlink-only and candidate-specific; duplicate and
  multi-status evidence produces one calibrated penalty per candidate.
- Semantic candidate-diff priority remains the leading ranking key.
- Zero-weight pressure retains evidence without changing selection arithmetic.
- The new numeric producer field is optional in runtime and exported schema
  contracts, with an explicit pre-change-row compatibility test.

Remaining maturity gaps:
- Continue candidate-specific resource/contact/readiness selection or ranking
  effects only where stable identity evidence supports them.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
