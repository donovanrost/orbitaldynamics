# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Validate repair replacement-ranking contracts.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Add runtime and exported JSON-schema validation for nested V2
`repair.replacement_ranking` explanations.

Why this slice:
`campaign_repair.v2` validated repaired activities only through their base
activity contract. Operator-visible ranking envelopes, rows, pressure evidence,
derived counts/ranks, and selected-candidate identity passed through unchecked.

Level 6 pillar:
Versioned compatibility and explainable operational-planning handoffs.

Implemented:
- Runtime validation covers ranking model/scope, nonempty rows, required row
  fields/types, stable IDs, and optional station/link/resource evidence.
- Derived validation enforces exact row counts, sequential ranks, unique
  candidate IDs, one selected row at rank 1, and matching selected candidate.
- Malformed non-map rows remain validation errors rather than raising during
  derived consistency checks.
- The exported `campaign_repair.v2` activity schema exposes the same nested
  ranking/evidence shape while unrelated repair metadata remains extensible.
- Standalone and bundled checked-in schema exports were regenerated through the
  documented export task.

Docs changed:
- `docs/feature_set/capability_map/13_v2_rolling_repair.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Ranking/schema/planner focused tests: `18 passed`.
- Schema plus checked-in export guard: `190 passed`.
- Campaign-planner area: `754 passed`.
- Final full suite with `--timeout 120000`: `3512 passed`.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- The validator runs only for `campaign_repair.v2` output activities and only
  tightens `repair.replacement_ranking`; other repair fields remain open.
- Runtime and exported schemas agree on required envelope/row/evidence types and
  nonempty ranking semantics; runtime adds cross-field consistency checks.
- Invalid row shapes cannot crash the derived pass, and mutation tests pin all
  new error paths.
- Export regeneration changed only the campaign-repair schema and all-contract
  bundle, with the executable-registry equality guard green afterward.

Previous published slice:
- `36e7c6d1` Explain repair projection pressure (`3509 passed`).

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
