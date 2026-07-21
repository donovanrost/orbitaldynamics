# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply explicitly scoped unavailable-resource quality-gate evidence during
CandidateRefresh contact selection.

Status:
Implemented and verified; publish pending.

Why this slice:
CandidateRefresh preserved and scored
`operational_quality_gate_unavailable_resource_summary.v1`, but its explicit
`blocked_contact_ids_by_spacecraft_id` evidence remained passive during
regenerated candidate selection.

Behavior changed:
- Contact-like candidates are filtered only when their exact ID appears under
  their spacecraft/scenario identity in the summary's blocked-contact map.
- Aggregate reasons/counts, blocking-dimension maps, and IDs scoped to another
  spacecraft do not filter.
- Evaluated candidates receive a schema-valid `candidate_rejection_report.v1`;
  rejected rows preserve source paths, artifact/report IDs, spacecraft scope,
  and trust boundaries.
- Matching prior candidates use
  `dropped_by_quality_gate_unavailable_resource` invalidation, and review/import
  handoffs preserve the rejection.
- Refreshes without this summary family retain the prior output shape.

Files changed:
- Added the focused CandidateRefresh quality-gate candidate filter.
- Wired build invalidation, warnings, capability metadata, and rejection output.
- Added accepted-state positive, aggregate/cross-spacecraft negative,
  no-summary compatibility, schema, operator-review, and import tests.
- Updated CandidateRefresh capability/artifact docs and the canonical public
  capability catalog.

Verification:
- Focused quality-gate/capability tests: 7 passed.
- CandidateRefresh plus rejection handoff suites: 764 passed.
- Capability catalog schema lint: pass, zero errors/warnings.
- Capability/golden/validation-reference suites: 20 passed.
- Full `mix test --timeout 180000`: 3,472 passed.
- `mix format --check-formatted` and `git diff --check`: pass.

Docs read/changed:
- Read Level 6 completeness, feature-complete definition, recommended roadmap,
  current capability snapshot, and CandidateRefresh pipeline/artifact docs.
- Updated planning-state refresh, candidate-refresh artifact, and current
  capability documentation for the exact-ID selection boundary.

Level 6 pillar advanced:
Operational readiness affects bounded selection while retaining explainability,
provenance, schema validation, and safe fail-closed scope.

Parent review:
Complete. Matching requires contact identity plus spacecraft scope; malformed or
aggregate-only inputs cannot become global blocks; observations are not matched;
existing source resolution and result-wrapper trust inheritance are reused; and
no Cadence write, approval, or execution authority was added.

Previous published slice:
- `cd8f4c97` Add manifest-backed atmospheric drag studies (`3469 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue contact/resource/readiness selection only where canonical artifacts
  expose unambiguous blocking evidence.
- Continue branch-local realized-feedback depth where public replay preserves a
  decision-safe signal.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked.
