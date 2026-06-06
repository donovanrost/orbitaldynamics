# `/goal` Prompt: Context-Efficient Autonomous Product Loop

```text
Drive OrbitalDynamics forward as a Cadence-facing LEO mission-planning
substrate, but optimize aggressively for low context usage.

Primary objective:
Drive the repository toward Level 6 mature operational-planning platform status
across the library, LEO campaign-planning, and Cadence-facing operational
planning surfaces. Implement the next highest-value product-completion slice
from the current documentation and codebase, but choose slices by closing the
largest maturity gap that is locally actionable. Work autonomously, keep the
main context small by reading narrowly, use a one-slice loop, and write compact
progress handoffs. After each completed slice, delegate the mechanical
commit/push handoff to a weaker subagent when one is available. If the run can
continue without violating the context-budget rule or requiring user input,
select the next slice and keep going.

Level 6 maturity compass:
Level 6 means OrbitalDynamics can serve as a stable planning platform for
Cadence-facing LEO operations. Treat the Level 6 target as the north star, not as
permission for a broad rewrite. Each slice should improve at least one of these
evidence pillars:

- validated model tiers and explicit known limits
- replaceable numerical backends with comparison artifacts
- durable schema-versioned artifacts and compatibility checks
- refreshed candidates from current mission state and realized feedback
- fleet-level resource, contact, station-calendar, and allocation behavior
- reproducible V1/V2/V3 branch trees with explainable score terms and deltas
- approval-aware automation boundaries, quality gates, and import readiness
- clear Cadence integration artifacts with no Cadence DB/API/execution coupling

Do not claim the overall goal is complete unless all three feature-complete
targets have current evidence: library feature completeness, LEO campaign
planning feature completeness, and Cadence-facing operational planning feature
completeness.

Run-duration expectation:
Assume this goal is meant to make sustained product progress, not stop after a
single quick slice. Context efficiency is a way to keep working longer. After a
completed slice, update the ledger, complete the commit/push handoff, choose the
next highest-value slice from the guide, and continue unless a stopping rule
below applies.

Context-budget rule:
The main agent is the orchestrator. It should avoid broad exploration, avoid
loading large doc sets, avoid pasting long command output, and avoid speculative
documentation expansion. If context grows, compress the current state into the
status ledger and resume with narrow reads instead of stopping solely because
context feels large. If using subagents, they must return compact structured
findings only.

First read:
Read only:

- `docs/autonomous_work_guide.md`
- `.codex/status/autonomous_product_loop.md` if it exists
- `.codex/prompts/context_efficient_autonomous_product_loop.md` if needed to
  refresh this goal's operating rules

Do not read all of `docs/`. Do not read every file under `docs/feature_set/`,
`docs/mission_planning/`, or `docs/artifacts/`. Use the guide to choose one
slice, then open only the docs linked for that slice.

Level 6 calibration reads:
When choosing a slice or reassessing after several completed slices, read only
these maturity-target docs, then return to narrow slice work:

- `docs/feature_set/completeness_levels/06_mature_operational_platform.md`
- `docs/feature_set/definition_of_feature_complete.md`
- `docs/feature_set/current_capability_snapshot.md`
- `docs/feature_set/recommended_roadmap.md`

Required slice-selection protocol:
Before editing code, write a short selection note in the conversation:

Selected slice:
Why this slice:
Level 6 pillar:
Current evidence gap:
Docs to read:
Likely files:
Likely tests:
Definition of done:

Then read only the listed docs/code/tests unless a blocker requires more.

Status ledger:
Maintain a compact handoff file at:

  `.codex/status/autonomous_product_loop.md`

Create the directory/file if missing. Keep it short. Update it after each
completed slice or before stopping.

Required ledger shape:

```text
# Autonomous Product Loop Status

Overall maturity target:
Current slice:
Status:
Files changed:
Tests run:
Docs/artifacts changed:
Level 6 pillar advanced:
Remaining maturity gaps:
Last commit:
Next candidate:
Blocked:
Notes:
```

Rules for the ledger:
- Keep it under roughly 120 lines.
- Replace stale details instead of appending endlessly.
- Do not paste command output into it.
- The next session should be able to resume from it plus
  `docs/autonomous_work_guide.md`.

Working loop:

1. Read `docs/autonomous_work_guide.md`.
2. Read `.codex/status/autonomous_product_loop.md` if it exists.
3. If the ledger says the last slice completed, reassess the remaining Level 6
   evidence gaps before choosing the next slice.
4. Choose exactly one vertical slice from the guide's decision queue, biased
   toward the weakest current maturity pillar.
5. Write the slice-selection note.
6. Read only the slice docs, likely code, and likely tests. Optionally delegate
   `slice_mapper` for bounded read-only mapping if the edit surface is not
   obvious.
7. Implement public behavior using existing repo patterns.
8. Add or update focused tests.
9. Update docs/artifacts only if public behavior or artifact shape changed.
10. Run targeted tests first.
11. Run broader tests only when planner/schema/artifact behavior changed enough
    to justify it.
12. Update the status ledger with the maturity pillar advanced and the next
    remaining gap.
13. Delegate `slice_reviewer` for read-only review of the completed slice.
14. Fix must-fix review findings, rerun focused verification, and update the
    ledger if needed.
15. Delegate the post-slice commit/push handoff.
16. Select the next highest-value slice and repeat unless a stopping rule
    applies.

Subagent strategy:
Use subagents only for bounded reconnaissance, review, or post-slice
commit/push handoffs. Prefer these project-scoped custom agents when available:

- `slice_mapper` from `.codex/agents/slice-mapper.toml` for optional read-only
  mapping before implementation
- `slice_reviewer` from `.codex/agents/slice-reviewer.toml` for read-only review
  after implementation and focused verification
- `git_slice_publisher` from `.codex/agents/git-slice-publisher.toml` for
  mechanical commit/push after review

If a custom agent is unavailable, use the closest built-in subagent with the
same sandbox and model intent. Do not let model selection block the handoff, and
do not use weaker subagents for product decisions, slice selection, or broad code
changes. Each subagent request must name a narrow target and require compact
output:

```text
Findings:
Files inspected:
Recommended edit:
Risks:
Tests:
```

Post-slice commit/push handoff:
After the main agent has implemented the slice, run verification, and updated
the ledger, delegate `git_slice_publisher` with this exact scope:

- inspect `git status --short` and the diff for the intended slice files
- run `git diff --check`
- stage only files owned by the completed slice, including the ledger when it
  changed
- commit with a concise message describing the slice
- push the current branch
- report the commit SHA, push destination, committed files, uncommitted
  unrelated files, and any blocker

Commit/push worker constraints:
- never stage unrelated dirty files
- never revert user or concurrent-agent changes
- never amend, rebase, reset, force-push, delete branches, or change remotes
- if push needs credentials, network approval, or other external state, request
  it through the normal approval path; if blocked, leave the local commit in
  place and report the blocker
- do not continue into the next product slice

Subagent constraints:
- no long code excerpts
- no full command output
- no broad repo summaries
- no reading all docs
- no speculative product expansion
- include file paths and line references when relevant
- no product decisions, slice selection, or broad code changes outside the
  parent orchestrator

Context-control rules:

- Prefer `rg` and targeted `sed`/`nl` reads.
- Prefer one or two focused files over whole-directory reads.
- Do not open large generated artifacts unless the selected slice requires
  them.
- Summarize command failures; do not paste full output unless needed to debug.
- For ExUnit failures, keep the relevant assertion, file, and line; omit long
  logs.
- Do not update broad roadmap docs unless the implemented behavior changes the
  roadmap or maturity status.
- Do not add new feature buckets during implementation goals.
- Do not refactor unrelated files.
- If context gets large, compress the handoff into the ledger and continue with
  narrow reads; do not stop solely because context is large.

Product priority order:
Use `docs/autonomous_work_guide.md` as the source of truth. Current default
order:

1. Typed operational activity and timeline semantics.
2. Resource and communications allocation semantics.
3. Quality gates, readiness, and import eligibility.
4. Branch-local candidate refresh depth.
5. Validation, compatibility, and challenge fixtures.

If test failures, dirty checkout state, or the status ledger show a current
contract break, prioritize restoring the broken public contract before expanding
features. For Level 6, a narrow green contract is more valuable than a broad
artifact surface that cannot validate.

Definition of done for one slice:

- public behavior exists behind a module/facade or validated artifact contract
- deterministic IDs/order are preserved for fixed inputs
- schema validation exists for new public artifacts when applicable
- focused tests cover normal and failure/edge behavior
- docs/artifacts are updated only where behavior changed
- assumptions, provenance, validation level, and known limits are explicit
- existing V1/V2/V3 behavior remains compatible unless changed deliberately
- the slice closes or measurably reduces a named Level 6 maturity gap
- status ledger is updated
- `slice_reviewer` found no must-fix publish blockers, or the parent fixed them
  and reran focused verification
- slice changes are committed and pushed, or a local commit/push blocker is
  recorded in the ledger

Definition of done for the overall maturity goal:

- the full test suite passes, including schema export/lint gates
- checked-in schemas and generated bundles match executable schema registries
- Level 6 status is supported by current evidence, not stale docs or memory
- library feature completeness evidence is current
- LEO campaign-planning feature completeness evidence is current
- Cadence-facing operational-planning feature completeness evidence is current
- V1 plan, V2 repair, V3 strategy, candidate refresh, quality/readiness, and
  Cadence import artifacts are covered by schema-validated examples
- remaining gaps are explicitly out of scope or recorded as future work; do not
  claim "complete" while a required Level 6 pillar is still partial

Verification guidance:

- Start with targeted tests, for example:
  `mix test test/orbital_dynamics/timeline_test.exs`
- Run schema export/lint tests when schema contracts change.
- Run broader `mix test` after broad planner/schema changes and before any claim
  that the goal or a maturity level is complete.
- For final maturity claims, also run schema export/lint and any checked-in
  artifact validation tasks named by the slice docs or status ledger.
- If Mix fails because of sandbox filesystem-lock issues, record the exact
  failure in the final answer and status ledger, then continue with available
  static verification if possible.

Stopping rules:
Stop cleanly after updating the status ledger when:

- the same blocker prevents progress on three consecutive attempted slices
- the next slice requires a product decision that cannot be resolved from the
  current docs/code/tests
- tests are blocked by environment issues that cannot be worked around
- the next change would be a broad unrelated refactor
- a correctness issue creates ambiguity requiring user input

Do not stop merely because one slice completed, context is large, or a prior
session claimed completion. Compress the handoff, verify the current evidence,
select the next Level 6 gap, and continue unless a stopping rule applies.

Final response:
Keep the final response short:

- selected slice completed
- key files changed
- tests run
- review status
- commit/push status
- next suggested slice
- any blockers
```
