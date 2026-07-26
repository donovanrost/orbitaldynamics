# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Bind repair ranking resource scopes to source summaries.

Status:
Implemented, reviewed, and verified; ready to publish.

Selection evidence:
- Repair replacement ranking now stamps every newly produced projected-resource
  risk indicator with the evaluated `candidate_id`, and executable validation
  requires that ID to match the enclosing ranking row.
- The same contract only type-checks the indicator `spacecraft_id`; it does not
  prove that the scope belongs to a resource summary that the exact embedded
  source candidate can consume.
- A hand-edited current artifact can therefore move an otherwise valid resource
  indicator from a `leo_1` candidate to a stable `leo_2` resource scope, keep
  its penalty and ranking arithmetic internally consistent, and still pass.
- Resource projection already owns deterministic source-summary matching:
  explicit resource-summary `spacecraft_id` matches candidate `spacecraft_id`
  or `scenario_id`, while one valid unscoped summary applies to all activities;
  duplicate and mixed wildcard scopes are excluded for operator review.
- Station, contact-intent, and contact-contention ranking evidence were audited
  first and already recompute their candidate-specific values from preserved
  source reports. Link shortfall and exact projected-resource values depend on
  the greedy projected activity set, so this slice binds only the independently
  reproducible resource scope instead of claiming a full projection replay.

Intended behavior:
- Expose and reuse the resource projection's normalized summary-to-activity
  scope semantics instead of maintaining a schema-only interpretation.
- For every current ranking risk indicator carrying `candidate_id`, require its
  `spacecraft_id` to be one of the exact valid source-resource scopes applicable
  to the uniquely embedded source candidate.
- Preserve candidates matched through either explicit `spacecraft_id` or
  `scenario_id`, and make the advertised single-unscoped-summary
  `all_spacecraft` behavior literal even when an activity declares its own
  spacecraft ID.
- Continue accepting legacy ranking indicators that omit `candidate_id`.
- Do not change projection arithmetic, filtering, scores, ranking, selection,
  schedules, operator/Cadence routing, approvals, provider writes, commanding,
  or execution authority.

Level 6 pillar advanced:
Fleet-scale resource decision auditability and executable evidence consistency.

Delivered files:
- shared resource-summary projection-scope semantics
- repair resource-pressure executable contract and focused challenge proofs
- focused docs, ledger, verification, and scoped publication

Verification:
- Focused resource projection, repair integration, and ranking contracts:
  `60 passed`.
- Adjacent repair-schema and resource-projection family: `330 passed`.
- Post-review projection/repair proofs: `56 passed`.
- Contact-allocation gate: `238 passed`.
- Saved-artifact schema lint: `155 artifacts`, zero errors, warnings, or
  remediation items.
- Pre-export full suite: `5160 passed` in `702.9s`.
- Schema/manifest exports and canonical repair/strategy reruns completed with
  passing artifact status and byte-identical hashes:
  - repair: `e28901d7988f7b2942b2c357ff53ce7b22d38f1cef26149b60d0570c4baa95d7`
  - strategy: `60a3f09b41b366aac91b6b82f6ed533abf618c857d886c841cc258b1e761a726`
  - manifest schema: `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`
  - schema bundle: `f77cd52510c692fbe33b7798f223303d14aab5c144520a3f1013131dc51db709`
- Schema export, manifest export, and golden artifact tests: `17 passed`.
- Final full suite: `5160 passed` in `720.3s`.
- `mix format --check-formatted` and `git diff --check` pass.

Review:
- `ResourceSummaryInput` now owns the exact normalized summary-to-activity
  matcher and projection scope ID used by `ResourceProjection`; schema code does
  not maintain a parallel identity rule.
- The shared wildcard branch now fulfills its documented all-activities rule
  even for activities that declare an explicit spacecraft ID. Scoped scenario
  and spacecraft matching, mixed wildcard review gating, and the wildcard edge
  all have direct regression assertions.
- The repair contract groups embedded source candidates by exact ID and only
  derives scopes for a unique candidate. Current indicators must match one of
  those valid normalized scopes at their exact indexed `.spacecraft_id` path;
  duplicate candidates, absent summaries, and review-gated summaries cannot
  manufacture a match.
- Scope binding is intentionally narrower than full risk replay: projected
  shortfall and resource values depend on the greedy activity prefix/future set
  that the compact ranking evidence does not fully preserve. This slice does
  not overclaim that reconstruction.
- Legacy indicators without `candidate_id` bypass only the new scope check.
  Existing type, candidate-ID, penalty, arithmetic, rank, and selection checks
  continue to run.
- The nine-file worktree contains only the ledger, three focused docs, shared
  projection semantics, the executable repair contract, and two test files.
  Schema exports and canonical repair/strategy artifacts are unchanged.

Last published slice:
- `66e90ee6` Bind repair suppressions to source evidence (`5160 passed`; every
  preserved suppressed candidate is backed by an exact source exclusion report
  while legacy omission and stale extra report IDs remain compatible).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Bind additional candidate-specific projection values only when their exact
  greedy projected activity set can be reproduced without copying full reports.
- Preserve remaining source collections only with explicitly lossless plural
  V2 shapes rather than first-map coercion.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After resource scope binding is executable, audit another explicit
allocation/resource decision surface before reconsidering raw refreshed-window
retention.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
