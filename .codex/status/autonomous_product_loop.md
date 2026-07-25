# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve pre-ranking CandidateRefresh exclusions in repair V2.

Status:
Implemented, reviewed, and verified; ready to publish.

Selection evidence:
- CandidateRefresh candidates can be excluded before replacement ranking by
  contact filters, allocation status, refresh budget, or resource filters.
- Repair V2's `source_candidate_activities` intentionally contains only the
  eligible ranking pool. In the allocation fixture, four exact source
  candidates become one eligible candidate, while the three excluded maps lose
  their score, score terms, and source-window context.
- Preserved source reports retain exclusion IDs, statuses, and reasons, but do
  not retain each excluded candidate's full original decision input.
- Raw refreshed-window retention remains weaker: selected window geometry is
  already embedded in source-window lineage, whereas excluded candidate maps
  are otherwise absent from the repair artifact.

Intended behavior:
- Preserve every exact excluded CandidateRefresh candidate map in source order
  at optional plural `source_suppressed_candidate_activities`, recursively
  normalizing encodable keys without reconstructing values.
- Keep `source_candidate_activities` as the eligible ranking pool; the two
  collections must be ID-unique, disjoint, and, for current artifacts with
  exclusions, reconcile to the source candidate count.
- Reuse the CandidateActivity executable contract for the new suppressed
  collection and the CandidateActivity JSON Schema for both collections, while
  leaving the looser legacy executable contract for existing eligible rows
  unchanged and accepting V2 artifacts that omit the new field.
- Do not change filters, penalties, ranking, selected candidates, repair output,
  operator/Cadence routing, schedules, approvals, or execution.

Level 6 pillar advanced:
Durable reproducible audit handoffs and schema/version compatibility.

Delivered files:
- lossless excluded-candidate resolution and repair artifact assembly
- executable partition and CandidateActivity schema contracts
- focused filter/schema proofs, docs, exports, and ledger

Verification:
- Focused resolver, four producer paths, and partition/schema contracts:
  `11 passed`.
- Adjacent CandidateRefresh repair/schema coverage: `37 passed`.
- Legacy-shape compatibility regression coverage after narrowing executable
  CandidateActivity validation to the new collection: `25 passed`.
- Contact-allocation gate: `238 passed`.
- Saved-artifact schema lint before and after exports: `155 artifacts`, zero
  errors, warnings, or remediation items.
- Pre-export full suite: `5157/5158 passed` in `722.2s`; the sole failure was
  the expected checked-in schema-export mismatch for the new optional field.
- Schema/manifest exports and canonical repair/strategy reruns completed with
  passing artifact status. Canonical hashes stayed byte-identical:
  - repair: `e28901d7988f7b2942b2c357ff53ce7b22d38f1cef26149b60d0570c4baa95d7`
  - strategy: `60a3f09b41b366aac91b6b82f6ed533abf618c857d886c841cc258b1e761a726`
  - manifest schema: `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`
- Schema export, manifest export, and golden artifact tests: `17 passed`.
- Final full suite: `5158 passed` in `693.4s`.
- `mix format --check-formatted` and `git diff --check` pass.

Review:
- The artifact resolver selects from the same union of suppression IDs as the
  existing eligibility filter, preserves source order and exact values, and
  only recursively normalizes encodable keys.
- The optional field is omitted when there are no exclusions. When present,
  executable contracts require nonempty, unique, disjoint collections and
  reconcile eligible plus suppressed rows to the raw CandidateRefresh count.
- Strict CandidateActivity executable validation applies to the new collection.
  Existing eligible rows retain their historical looser executable contract so
  legacy and fixture-backed V2 artifacts remain readable; both fields share the
  existing CandidateActivity JSON Schema.
- Generated changes are limited to `campaign_repair.v2.schema.json` and the
  aggregate schema bundle. Canonical no-suppression repair and strategy outputs
  are byte-identical, confirming no filtering, scoring, ranking, scheduling,
  routing, or authority drift.

Last published slice:
- `38746c15` Bind repair resource evidence to candidates (`5152 passed`;
  current ranking evidence is candidate-bound while legacy V2 stays readable).

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
After excluded decision inputs are durable, audit suppression-reason binding or
another explicit allocation/resource decision surface before reconsidering raw
refreshed-window retention.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
