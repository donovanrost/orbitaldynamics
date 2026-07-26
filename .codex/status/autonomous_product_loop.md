# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve and type the CandidateRefresh sampling horizon in Repair V2.

Status:
Implemented and fully verified from published commit `d305d784`; publication
pending.

Delivered behavior:
- CandidateRefresh now validates its embedded `remaining_horizon` as numeric
  `starts_at_s`, `ends_at_s`, and positive `output_step_s`, with ordered bounds,
  cadence no larger than duration, optional exact `duration_s`, and an optional
  matching `remaining_horizon.v1` tag.
- The exported CandidateRefresh and Repair V2 JSON Schemas expose the same typed
  embedded shape while remaining compatible with the existing untagged map.
- Repair V2 preserves the exact normalized CandidateRefresh map at
  `source_candidate_refresh_remaining_horizon`; it remains absent without a
  CandidateRefresh map and validates supplied source values at nested paths.
- Strategy V3 branch repairs and the readiness source handoff preserve the same
  source evidence. The operative Repair `remaining_horizon` remains independent.
- No filtering, ranking, selection, scheduling, review/import rows, provider
  state, commanding, or authority changed.

Selection evidence:
- Repair V2 retained only its own horizon and therefore lost the exact sampled
  CandidateRefresh opportunity horizon, notably `output_step_s`.
- Runtime previously checked only for a map with an `output_step_s` key, while
  exported JSON Schema described the horizon only as `{type: object}`.
- The standalone `remaining_horizon.v1` contract already defined the reusable
  interval, cadence, and optional-duration semantics.
- Reservation-conflict and capacity summaries remain intentionally review-only;
  the authoritative allocation report already removes unusable contacts.

Level 6 pillar advanced:
Reproducible sampled opportunity sets and versioned artifact compatibility.

Verification evidence:
- Focused CandidateRefresh/producer/Repair/Strategy gate: `37 passed`.
- Adjacent refresh-window, fallback/freshness, generated-repair, assumptions,
  and warnings gate: `25 passed`.
- Pre-export Repair source-family gate: `234/235 passed`; the sole failure was
  the expected stale readiness handoff.
- Pre-export artifact lint: `155` artifacts, `0` errors, `0` warnings.
- Pre-export full suite: `5216/5220 passed` in `705.2s`; exactly four expected
  parity failures: readiness handoff, schema exports, canonical Repair, and
  canonical Strategy.
- Post-export schema/manifest/golden/readiness/contract gate: `35 passed`.
- Post-export Repair source-family gate: `235 passed`.
- Review-driven standalone/embedded horizon regression gate: `17 passed`.
- Post-export artifact lint: `155` artifacts, `0` errors, `0` warnings.
- Final full suite: `5220 passed` in `721.0s`.
- `mix format --check-formatted` and `git diff --check` pass.

Generated-artifact proof:
- `candidate_refresh.v1` changed only its `remaining_horizon` property from an
  untyped object to the typed embedded contract.
- `campaign_repair.v2` gained one optional typed
  `source_candidate_refresh_remaining_horizon` property; the bundle reflects
  only the CandidateRefresh and Repair registry changes.
- The readiness handoff and canonical Repair each gained exactly one source
  horizon. Strategy gained it in exactly `26` generated repair branches; five
  identity-bearing fields rolled with strategy ID
  `a266966c020cc8d84d46275db025f65a6b4034c12618b9d137e2baff9c50f1a4`.
- `schemas/study_manifest.v1.schema.json` remained byte-identical.

Final generated hashes:
- schema bundle: `dc7636c981804bc43b9e2b22552e886b593dfab6ef09d7e9e3f9086f846a22c1`
- manifest schema: `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`
- readiness handoff: `330a08d138b8c82ced6f1202e6c9d125389d204126471780fc1bdf22e409f6f5`
- canonical Repair: `77777e7ee2e811b75b42b7f8e11f75fcc3d9d1c62a8855d8d42ec8f8de6a7afe`
- canonical Strategy: `7134420fb9ed7a115c8fa74403cc29ec365e3f0d2b52a7559269b6234d8f7023`

Last published slice:
- `d305d784` Preserve CandidateRefresh warnings in Repair V2 (`5212 passed`).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions only from authoritative,
  candidate-identified evidence while preserving provider/Cadence boundaries.
- Bind additional candidate-specific projection values only when they add
  compact decision evidence beyond current exact shortfall/risk indicators.
- Audit remaining CandidateRefresh envelope fields only when they add durable
  evidence beyond existing identity, provenance, assumptions, warnings,
  horizon, and source-report surfaces.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
From the clean published checkout, reassess the remaining authoritative
fleet-scale decision surfaces before selecting another bounded slice.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
