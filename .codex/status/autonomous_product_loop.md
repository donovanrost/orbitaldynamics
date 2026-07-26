# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Bind preserved repair suppressions to their source exclusion evidence.

Status:
Implemented, reviewed, and verified; ready to publish.

Selection evidence:
- Repair V2 now preserves exact pre-ranking CandidateRefresh exclusions at
  `source_suppressed_candidate_activities` and validates that the eligible and
  suppressed collections are unique, disjoint, and count-reconciled.
- The current executable partition contract does not prove that a suppressed
  candidate ID is named by any preserved contact-filter, contact-allocation,
  refresh-budget, or resource-filter report.
- A hand-edited artifact can replace a suppressed candidate with another valid
  CandidateActivity, keep both partition counts valid, and still pass despite
  losing the decision evidence that explains the exclusion.
- The producer already has one canonical union of suppression IDs across all
  four report families, including allocation status normalization and ID alias
  handling; reusing it avoids a second interpretation in schema code.

Intended behavior:
- When `source_suppressed_candidate_activities` is present, require every row's
  exact candidate ID to be backed by at least one preserved source exclusion
  report at an exact indexed validation path.
- Resolve contact, allocation, budget, and resource evidence with the existing
  `RepairCandidateInputs.suppressed_candidate_ids/1` semantics by projecting
  preserved source reports into its CandidateRefresh report view.
- Allow source reports to mention stale or out-of-scope IDs that are absent from
  the raw candidate collection; the producer already ignores those IDs.
- Continue accepting legacy V2 artifacts that omit the suppressed collection.
- Do not add artifact fields or change filtering, scores, ranking, selection,
  schedules, operator/Cadence routing, approvals, or execution authority.

Level 6 pillar advanced:
Durable reproducible audit handoffs and executable evidence consistency.

Delivered files:
- executable evidence-binding contract and exact-path tests
- focused producer/schema proofs, docs, ledger, and verification

Verification:
- Focused four-family producer and suppressed-candidate contract coverage:
  `13 passed`.
- Adjacent CandidateRefresh repair/schema coverage: `39 passed`.
- Contact-allocation gate: `238 passed`.
- Saved-artifact schema lint: `155 artifacts`, zero errors, warnings, or
  remediation items.
- Pre-export full suite: `5160 passed` in `667.5s`.
- Schema/manifest exports and canonical repair/strategy reruns completed with
  passing artifact status and byte-identical hashes:
  - repair: `e28901d7988f7b2942b2c357ff53ce7b22d38f1cef26149b60d0570c4baa95d7`
  - strategy: `60a3f09b41b366aac91b6b82f6ed533abf618c857d886c841cc258b1e761a726`
  - manifest schema: `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`
  - schema bundle: `f77cd52510c692fbe33b7798f223303d14aab5c144520a3f1013131dc51db709`
- Schema export, manifest export, and golden artifact tests: `17 passed`.
- Final full suite: `5160 passed` in `728.0s`.
- `mix format --check-formatted` and `git diff --check` pass.

Review:
- The contract projects only the four preserved source reports into the same
  report keys consumed by `RepairCandidateInputs.suppressed_candidate_ids/1`,
  so allocation normalization and report-row ID aliases cannot drift from the
  producer's eligibility decision.
- Every preserved suppressed row must have matching evidence at an exact
  indexed `.id` path. Extra report IDs remain allowed because the producer
  already ignores suppression evidence for candidates absent from the raw set.
- Legacy artifacts that omit the new collection still bypass the partition and
  evidence checks exactly as before.
- The worktree contains only the ledger, docs, executable pool contract, and its
  tests. Schema exports, canonical artifacts, filtering, scoring, ranking,
  scheduling, routing, approvals, and authority behavior are unchanged.

Last published slice:
- `bd4a394b` Preserve suppressed repair candidates (`5158 passed`; exact
  excluded CandidateRefresh decision inputs are durable while canonical repair
  and strategy artifacts remain byte-identical).

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
After suppression evidence binding is executable, audit another explicit
allocation/resource decision surface before reconsidering raw refreshed-window
retention.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
