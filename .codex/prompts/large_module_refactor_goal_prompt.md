# `/goal` Prompt: Large Module Refactor Loop

```text
Refactor the largest OrbitalDynamics modules and tests into smaller,
responsibility-focused units without changing public behavior.

Primary objective:
Reduce the maintenance risk of the massive schema, candidate-refresh, campaign
planner, operator-review, and matching test files by extracting cohesive
internal modules and family-specific tests behind stable public facades.

This is a behavior-preserving architecture cleanup effort. Do not treat line
count reduction by itself as success. Success means the same public APIs,
artifact contracts, deterministic outputs, checked-in schema exports, and tests
continue to work while the code becomes easier to navigate and safer to change.

Why this matters:
The current checkout has several very large files whose size is driven mostly
by private helper and contract-family accumulation:

- `test/orbital_dynamics/campaign_planner_test.exs`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/schema_test.exs`
- `lib/orbital_dynamics/operator_review.ex`

The main refactor strategy is facade-preserving extraction:

- keep public modules and public function names stable unless a narrower
  intentional API cleanup is explicitly justified and tested
- move cohesive private implementation clusters into internal modules
- keep generated JSON Schema and executable schema validation aligned
- split append-only test ledgers by artifact family when that improves focused
  verification
- avoid broad rewrites, behavior changes, formatting churn, and unrelated
  cleanup

Run-duration expectation:
Assume this goal is intended to run for hours across multiple small refactor
slices. Do not stop after one extraction if the checkout is healthy and another
bounded slice is obvious. Use context efficiency to continue longer, not as a
reason to stop early.

Stop only when:
- the same blocker prevents progress on three consecutive attempted slices,
- a public API or artifact behavior decision cannot be inferred safely,
- required tests cannot run because of the environment and no useful static
  refactor work remains,
- continuing would require destructive action, credentials, or unsafe VCS
  changes,
- the goal budget/system stops the run.

First read:
Read only:

- this prompt
- `docs/autonomous_work_guide.md`
- `.codex/status/large_module_refactor.md` if it exists
- the current `git status --short`

Do not read all docs. Do not read all large files end to end. Use `rg`,
targeted `sed`, and function-boundary searches to map the current slice.

Initial inventory:
Before selecting the first slice in a fresh run, refresh the live hotspot
inventory with targeted commands such as:

- `rg --files | xargs wc -l | sort -nr | head -40`
- public/private function counts for the target modules
- public entry-point searches for the target module
- focused test counts for the matching test file

Use the current checkout as authoritative. Prior notes are useful context, but
file sizes, dirty worktree state, and test state may have changed.

Status ledger:
Maintain a compact handoff file at:

  `.codex/status/large_module_refactor.md`

Create it if missing. Update it after every completed refactor slice and before
any pause. Keep it concise; replace stale details instead of appending
endlessly.

Ledger shape:

  # Large Module Refactor Status

  Overall objective:
  Current slice:
  Status:
  Files changed:
  Public APIs preserved:
  Behavior/schema changes:
  Tests run:
  Verification gaps:
  Last commit:
  Next candidate:
  Blocked:
  Notes:

Slice-selection protocol:
Before editing each slice, write a short note:

Selected slice:
Why this slice:
Current coupling/problem:
Public facade to preserve:
Likely extraction target:
Likely files:
Likely tests:
Definition of done:

Then read only the listed code/tests unless a blocker requires more.

Recommended slice order:

1. Schema registry/export/validation extraction.
   `lib/orbital_dynamics/schema.ex` mixes contract registry data, JSON Schema
   export, contract inference, linting, executable validation, and many
   artifact-family validators. Start with low-risk internal boundaries:
   `Schema.Registry`, `Schema.JsonExport`, `Schema.Inference`,
   `Schema.Report`, or family validator modules. Keep `OrbitalDynamics.Schema`
   as the public facade for `contracts/0`, `contract/1`, `json_schema/1`,
   `json_schema_bundle/0`, `validate_artifact/2`, `validation_report/2`, and
   lint helpers.

2. Schema tests by contract family.
   `test/orbital_dynamics/schema_test.exs` behaves like an append-only
   contract ledger. Split independent families into focused test files only
   when their helpers and setup can move without weakening assertions. Prefer
   moving whole coherent groups over extracting individual isolated tests.

3. Candidate-refresh replay-summary extraction.
   `lib/orbital_dynamics/candidate_refresh.ex` exposes many
   `*_replay_summary/1` families. Keep the public functions in
   `OrbitalDynamics.CandidateRefresh`, but delegate cohesive families to
   internal modules such as `CandidateRefresh.ReplaySummary.*` or another local
   naming pattern that fits the codebase.

4. Candidate-refresh tests by replay/source family.
   Split `test/orbital_dynamics/candidate_refresh_test.exs` around the same
   family boundaries used by the production extraction. Preserve fixture
   coverage and exact contract assertions.

5. Campaign planner generation boundaries.
   `lib/orbital_dynamics/campaign_planner.ex` already has V1 `build/2`, V2
   `repair/1`, and V3 `strategy/1` entry points. Extract implementation behind
   `CampaignPlanner.Build`, `CampaignPlanner.Repair`,
   `CampaignPlanner.Strategy`, or more specific modules. Keep the current
   public entry points and structs stable.

6. Campaign planner tests by generation and feedback source.
   Split `test/orbital_dynamics/campaign_planner_test.exs` along V1/V2/V3,
   branch-feedback, repair, lint, and strategy-source boundaries. Do not
   weaken regression coverage to make the file smaller.

7. Operator-review adapter extraction.
   `lib/orbital_dynamics/operator_review.ex` is an adapter registry with many
   `from_*` public functions. Keep public adapters stable while moving source
   row mapping by artifact family into internal modules.

Working loop:

1. Refresh the current hotspot and dirty-worktree state.
2. Pick one bounded extraction that has a clear facade and matching focused
   tests.
3. Write the slice-selection note.
4. Read only the relevant function cluster and matching tests.
5. Add the new internal module or test file.
6. Move code mechanically first; make semantic edits only when required to
   preserve behavior.
7. Keep public facade functions delegating to the new module.
8. Run formatting on touched files.
9. Run the narrowest focused tests that prove behavior did not change.
10. If schema-visible behavior was touched, run schema/export/lint verification
    and refresh checked-in exports when required.
11. Run `git diff --check`.
12. Update `.codex/status/large_module_refactor.md`.
13. Perform a bounded local review or use a read-only review sidecar if
    available.
14. Fix must-fix review findings and rerun focused verification.
15. Commit/push only the completed slice when appropriate and safe, leaving
    unrelated dirty files alone.
16. Select the next bounded slice and continue.

Definition of done for each refactor slice:

- Public APIs and public module names remain compatible.
- Existing artifact maps remain deterministic for fixed inputs.
- JSON Schema exports and executable validators remain aligned.
- Focused tests covering the moved behavior pass.
- Broader tests are run when the touched surface is shared enough to justify
  them.
- New internal module names match existing repo style.
- The original large file delegates rather than duplicating moved logic.
- No unrelated dirty files are staged, reverted, reformatted, or edited.
- The refactor ledger records the current state and next candidate.

Verification guidance:

- For pure internal extraction, prefer focused file-level tests first.
- For schema refactors, include `mix test test/orbital_dynamics/schema_test.exs`
  or narrower selectors when possible, plus schema export tests when JSON
  Schema generation moved.
- For candidate-refresh extraction, include focused selectors or
  `mix test test/orbital_dynamics/candidate_refresh_test.exs`.
- For campaign-planner extraction, include focused selectors or
  `mix test test/orbital_dynamics/campaign_planner_test.exs`.
- Run broader `mix test` only after broad shared-module moves or before a
  milestone claim.
- `git diff --check` is required before considering a slice complete.

Schema-specific rules:

- Treat `lib/orbital_dynamics/schema.ex` as the public facade unless an
  explicit API change is approved.
- Do not move contract definitions, export helpers, or validators in a way that
  changes generated schema output accidentally.
- If checked-in schema files under `schemas/` change, verify they changed
  intentionally and are regenerated through the repo's export command rather
  than hand-edited.
- Runtime schema changes, checked-in exports, and schema tests must move
  together.

Test-splitting rules:

- Test extraction is useful only when it improves focused verification.
- Keep helper setup close to the family it supports.
- Prefer one coherent new test module per artifact/generation family.
- Do not replace high-signal fixture assertions with shallow smoke tests.
- Preserve failure/edge-case coverage and deterministic ordering assertions.

VCS constraints:

- Inspect `git status --short` before edits and before commit.
- Never revert or stage unrelated user/concurrent-agent changes.
- Never use destructive commands such as reset, checkout, clean, or force-push.
- If the worktree is dirty, identify which changes belong to the current slice
  and leave the rest alone.
- If push is blocked by credentials or network approval, keep the local commit
  and record the blocker.

Completion report:
At the end of a run, summarize:

- refactor slices completed,
- public facades preserved,
- files/modules created or split,
- tests run and results,
- schema/export verification if relevant,
- remaining highest-value refactor candidates,
- blockers or verification gaps.
```
