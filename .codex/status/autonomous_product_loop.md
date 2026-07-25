# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Bind replacement resource-pressure evidence to its evaluated candidate.

Status:
Implemented, reviewed, and verified; ready for scoped publication.

Selection evidence:
- The canonical CandidateRefresh has two refreshed windows and two candidate
  lineage rows; each lineage row already embeds the exact selected source
  window. Retaining all raw detected windows would duplicate selected evidence
  and grow with events that never become candidates.
- Repair replacement ranking computes resource-risk indicators from a
  candidate-specific projected plan, but the nested indicator maps do not name
  the candidate whose projection produced them.
- `first_resource_pressure_activity_id` is not a substitute: projected plans
  include the evaluated candidate plus future planned activities, so the first
  pressure activity can differ from the candidate under comparison.
- Executable and JSON Schema validation currently require only indicator type,
  severity, reason, and spacecraft ID; a detached or misbound indicator can
  validate without its decision identity.

Delivered behavior:
- Stamp every replacement-ranking resource-risk indicator with the stable
  `candidate_id` of the ranking row whose projected plan produced it.
- Schema-type that identity and executable-validate its exact equality with the
  parent ranking row at the indicator's indexed path. Continue accepting its
  omission in pre-slice V2 evidence for backward compatibility while proving
  the current producer always emits it.
- Add identity only at the candidate-specific ranking boundary; do not alter
  generic resource-projection reports or infer it from compact aggregate maps.
- Keep all penalty arithmetic, ordering, selected candidate, repair output,
  review/Cadence routing, schedules, approvals, and execution unchanged.

Level 6 pillar advanced:
Durable reproducible audit handoffs and schema/version compatibility.

Delivered files:
- candidate-specific resource-risk evidence assembly
- executable and JSON Schema identity contracts
- focused ranking/schema proofs, docs, exports, and ledger

Verification:
- Focused resource-ranking producer and schema contracts: `13 passed` in
  15.2s; the final malformed/misbound identity contract rerun passed `4` tests
  in 0.8s.
- Adjacent resource-projection and replacement-ranking family: `24 passed` in
  11.0s.
- Contact-allocation regression family: `238 passed` in 15.8s.
- Schema lint before and after export: `155` artifacts passed with `0` errors
  and `0` warnings.
- Pre-export full suite: `5151/5152 passed` in 658.1s; the only expected failure
  was the checked-in repair JSON Schema export.
- Regenerated all schema exports, the manifest schema, and both canonical
  campaigns. Only the repair schema and schema bundle changed.
- Canonical repair stayed byte-identical at
  `e28901d7988f7b2942b2c357ff53ce7b22d38f1cef26149b60d0570c4baa95d7`;
  canonical strategy stayed byte-identical at
  `60a3f09b41b366aac91b6b82f6ed533abf618c857d886c841cc258b1e761a726`;
  the manifest schema stayed at
  `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`.
- Checked-in schema export gate: `3 passed` in 51.7s.
- Golden artifact gate: `12 passed` in 38.7s.
- Final full suite: `5152 passed` in 697.8s.
- `mix format --check-formatted` and `git diff --check` passed.

Review:
- Candidate identity is added only after a generic resource projection is
  converted into candidate-specific ranking evidence; generic source reports
  remain unchanged.
- Every current indicator receives the exact parent row candidate ID. A
  supplied different or malformed ID fails at the indexed indicator path.
- Pre-slice V2 indicators that omit `candidate_id` remain valid, avoiding a
  breaking change to the existing repair contract.
- Penalty values, arithmetic, row order, selected candidates, repair output,
  review/Cadence routing, canonical campaign content, and all authority and
  execution boundaries are unchanged.

Last published slice:
- `b9972a6c` Preserve V2 source validation records (`5152 passed`; exact ordered
  model evidence is retained, typed, and audit-only).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep compact aggregate maps provenance-only.
- Preserve remaining source collections only with explicitly lossless plural
  V2 shapes rather than first-map coercion.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After candidate-bound resource evidence is durable, audit another explicit
allocation/resource decision surface before reconsidering raw refreshed-window
retention.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
