# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Contract V1 activity source windows.

Status:
Complete and parent-reviewed; ready to publish.

Delivered:
- Required `source_window_id` plus nested `source_window.id` evidence on selected,
  candidate, and ranked-timeline activity rows.
- Validated nested IDs against the shared stable-ID policy and reconciled valid
  nested identity to the outer source-window ID.
- Exported nested source-window ID as required on all three V1 activity surfaces.
- Added a shared stable-ID validity predicate without changing existing stable-ID
  validation behavior.
- Preserved the existing downlink shape owner while covering observe-style rows
  in the consolidated V1 activity contract.
- Added required/map/stable-ID/equality/downlink/export coverage.
- Regenerated only `campaign_plan.v1` and the aggregate schema bundle.
- Updated V1 generation, planning, reproducibility, and roadmap documentation.

Review calibration:
- Nine pre-fix live missing-ID, missing-window, and mismatch mutations passed
  across selected, candidate-observe, and ranked rows.
- Missing/malformed downlink windows retain exactly one existing map remediation;
  the V1 contract does not duplicate it.
- Equality runs only after both IDs satisfy stable-ID policy, preventing malformed
  IDs from adding misleading mismatch errors.
- Parent review found source-window logic cohesive inside the 185-line activity
  contract and left producer/repair behavior unchanged.

Verification:
- Focused lineage: `7 passed`; activity/score/plan integration: `27 passed`.
- Plan/export integration: `118 passed`; schema plus lint area: `305 passed`.
- Planner area: `754 passed`.
- Final full suite: `3618 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` pass.

Previous published slice:
- `5f771a8d` Reconcile V1 activity scores (`3611 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth where evidence is genuinely
  candidate-specific.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, and mechanical publish checks.
