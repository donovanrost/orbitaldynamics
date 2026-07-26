# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Explain Repair replacement link pressure with projected demand and throughput.

Status:
Complete and verified from published base `358a0863`; scoped publish pending.

Delivered behavior:
- Link-pressured `repair.replacement_ranking` rows now preserve projected
  `link_capacity_pressure_required_downlink_mb` and
  `link_capacity_pressure_selected_capacity_adjusted_throughput_mb` beside the
  existing positive shortfall and calibrated penalty.
- Nominal alternatives omit all three link-pressure evidence values, retaining
  the compact row shape and unchanged ranking arithmetic.
- Runtime validation requires the new operands to appear together and, when
  present, enforces `selected throughput + shortfall = required demand` within
  `1.0e-9`. Pre-slice shortfall-only rows remain compatible.
- The exported Repair V2 schema declares both operands as optional non-negative
  numbers. Documentation records the replay equation and artifact-only,
  no-global-optimization boundary.
- Candidate filtering, ranking score, selection, schedule mutation,
  review/import routing, provider state, commanding, and authority are
  unchanged.

Verification evidence:
- Focused producer/schema gate: `11 passed`; expanded replacement-selection gate:
  `28 passed`.
- Saved-artifact lint before and after export: `155` artifacts, `0` errors,
  `0` warnings.
- Pre-export full suite: `5239/5240 passed`; the sole failure was the expected
  checked-in JSON Schema parity mismatch.
- Schema/golden/source-handoff post-export gate: `43 passed`.
- Final full suite: `5240 passed` in `673.0s`.
- Structural proof: the pressured fixture records required `100.0`, selected
  capacity-adjusted throughput `99.0`, and shortfall `1.0`; nominal rows omit all
  three values. Legacy, both partial-pair directions, missing-shortfall, and
  inconsistent-equation challenges are covered.
- Regeneration changed only `campaign_repair.v2.schema.json` and the aggregate
  schema bundle. Canonical Repair, Strategy, readiness, manifest, and
  CandidateRefresh artifacts remained byte-stable.
- Published hashes prepared for review:
  - Repair schema: `7a01334e751fcb2ba95ffb903ff1a50517a722e7d4f17163ca521436915ab42b`
  - Schema bundle: `fa6dd8d33224c98168a723a99c9372560dae94a36bf9a0c8c842fee037801abf`
  - Repair artifact: `cc41834e706fd1e04a4c5578032fdf99ceeba949a02fd75fc54c8b70cdc30d8a`
  - Strategy artifact: `57602722702969da587e2754df84bca1e06e86cc32fa5af7f3f78451b72f9985`

Level 6 pillar advanced:
Candidate-specific decision explainability and versioned artifact compatibility.

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions only from authoritative,
  candidate-identified evidence while preserving provider/Cadence boundaries.
- Bind additional candidate-specific projection values only when they add
  compact decision evidence beyond current exact shortfall/risk indicators.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
From the clean published checkout, audit remaining fleet-scale Repair decision
rows for compact source operands that are already computed but discarded.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, verification, and publish checks.
