# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve CandidateRefresh model limits in Repair V2.

Status:
Complete and verified from published base `a959aa14`; publication pending.

Selection evidence:
- Generated CandidateRefresh artifacts always publish the exact six-item
  executable `model_limits` list that declares precomputed-window, sampled-
  boundary, thin-filter, deterministic-budget, and no-schedule-mutation limits.
- CandidateRefresh runtime validation and JSON Schema already pin that exact
  list, rejecting stale or reordered limits.
- Repair V2 publishes its own distinct `model_limits` but drops the source
  CandidateRefresh boundary, so a Repair-only audit consumer cannot establish
  which candidate-generation limitations conditioned the source evidence.
- CandidateRefresh identity copying was rejected as redundant with
  `assumptions.candidate_source`, provenance, and the accepted-state reference;
  raw candidates and invalidations were rejected as redundant with existing
  source-candidate and candidate-diff surfaces.

Delivered behavior:
- Preserve the exact CandidateRefresh list at
  `source_candidate_refresh_model_limits`, including list order, only when the
  source supplies a list.
- Reuse the CandidateRefresh executable list for Repair runtime validation and
  the CandidateRefresh JSON Schema property for Repair schema export, avoiding
  a second source of truth.
- Keep the field optional without CandidateRefresh or without a list and reject
  stale, reordered, or non-list supplied values at the exact source path.
- Preserve the list through Strategy V3 branch repairs and the readiness
  handoff without changing filtering, ranking, selection, scheduling,
  review/import rows, provider state, commanding, or authority.

Level 6 pillar advanced:
Candidate-generation model-boundary traceability and versioned artifact
compatibility.

Verification:
- Focused producer and CandidateRefresh/Repair runtime/schema tests: `21 passed`.
- Large Repair/Strategy source integrations: `18 passed`.
- Adjacent build/freshness and CandidateRefresh source-family contracts:
  `43 passed`.
- Pre-export complete Repair source gate: `246/247 passed`; the sole failure was
  the expected stale readiness handoff.
- Pre-export full suite: `5236/5240 passed`; all four failures were classified
  checked-in parity drift (readiness, Repair schema export, canonical Repair,
  canonical Strategy), with no behavioral failures.
- Post-export schema/manifest/golden/readiness/model-limit gate: `39 passed`.
- Complete Repair source-contract gate: `247 passed`.
- Saved-artifact lint: `155` artifacts, zero errors and zero warnings.
- Final full suite: `5240 passed` in `725.6s` (`556.9s` async, `168.6s` sync).
- `mix format --check-formatted` and `git diff --check` pass.
- Structural proof: Repair reuses CandidateRefresh's exact list schema;
  readiness and canonical Repair retain the list; Strategy retains one
  identical list in all `25` generated-refresh branches. `baseline` has no
  refresh, while the checked-in legacy `operator_station_outage` refresh
  legitimately omits the optional list.
- Generated hashes: CandidateRefresh schema remained byte-identical at
  `8f3495e118c97036ac0cedb11d7b503ecde0a23f08fc1fd216b46c192b95b7a9`;
  Repair schema
  `4dbcebbdb9fcfe6aee0a389040c6f857f2ae6f699becc6136a1ffc5665219359`;
  bundle
  `e53b1e725a331c485c8e7f2859e90462d13b1c09564f2c2978d5aa16314bcff4`;
  readiness
  `817cdd87c316d0c8da813608172e21eab044290fb136584ac7c39d9ad6bd7eec`;
  Repair
  `cc41834e706fd1e04a4c5578032fdf99ceeba949a02fd75fc54c8b70cdc30d8a`;
  Strategy
  `57602722702969da587e2754df84bca1e06e86cc32fa5af7f3f78451b72f9985`.
- Manifest schema remained byte-identical at
  `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`;
  regenerated Strategy ID is
  `5e57012affb26253372b03dd162ef0c8cbbad663c66d8b5e634be0259fb6f846`.

Last published slice:
- `a959aa14` Preserve CandidateRefresh accepted state in Repair V2 (`5234
  passed`; exact typed accepted-state references retained in all 26 refresh-
  conditioned Strategy branches with no review/import routing).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions only from authoritative,
  candidate-identified evidence while preserving provider/Cadence boundaries.
- Bind additional candidate-specific projection values only when they add
  compact decision evidence beyond current exact shortfall/risk indicators.
- Audit remaining CandidateRefresh envelope fields only when they add durable
  evidence beyond existing identity, provenance, accepted-state, assumptions,
  warnings, horizon, feedback, model-limit, and source-report surfaces.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After source model-boundary traceability is executable, reassess the remaining
authoritative fleet-scale decision surfaces from the clean published checkout.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
