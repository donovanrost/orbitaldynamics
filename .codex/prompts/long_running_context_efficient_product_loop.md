# `/goal` Prompt: Long-Running Context-Efficient Product Loop

```text
Drive OrbitalDynamics forward as a Cadence-facing LEO mission-planning
substrate for a long autonomous work session. Optimize for low context usage,
but do not stop after a single small slice.

Primary objective:
Work through multiple product-completion slices from
`docs/autonomous_work_guide.md`, implementing, testing, documenting, and
recording progress. Continue for a workday-length autonomous run unless
genuinely blocked.

Run-duration expectation:
Assume this goal is intended to keep working for hours, not minutes. Do not
stop merely because one slice is complete, tests passed, context feels
moderate, or the next slice requires normal code exploration. After each
completed slice, update the ledger, pick the next highest-value slice, and keep
going.

Stop only when:
- the same blocker prevents progress on three consecutive attempted slices,
- the next step requires user/product input that cannot be inferred safely,
- required tests or commands are impossible to run because of an environment
  issue and there is no useful static work remaining,
- continuing would require destructive action or external credentials,
- the goal budget/system stops the run.

Context-budget rule:
The main agent is the orchestrator. Keep context small by reading narrowly,
summarizing exploration, using the status ledger, and avoiding broad doc/code
dumps. Context efficiency is a way to continue longer, not a reason to stop
early.

First read:
Read only:

- `docs/autonomous_work_guide.md`
- `.codex/status/autonomous_product_loop.md` if it exists

Do not read all of `docs/`. Do not read every file under `docs/feature_set/`,
`docs/mission_planning/`, or `docs/artifacts/`. Use the guide to choose the
current slice, then open only the docs linked for that slice.

Status ledger:
Maintain a compact handoff file at:

  `.codex/status/autonomous_product_loop.md`

Create it if missing. Update it after every completed slice and before any
pause.

Keep the ledger concise. Replace stale details instead of appending endlessly.
It should stay under roughly 160 lines.

Ledger shape:

```text
# Autonomous Product Loop Status

Current slice:
Status:
Completed slices:
Files changed:
Tests run:
Docs/artifacts changed:
Next candidate:
Blocked:
Notes:
```

Slice-selection protocol:
Before editing each slice, write a short note:

Selected slice:
Why this slice:
Docs to read:
Likely files:
Likely tests:
Definition of done:

Then read only the listed docs/code/tests unless a blocker requires more.

Working loop:

1. Read `docs/autonomous_work_guide.md`.
2. Read `.codex/status/autonomous_product_loop.md` if it exists.
3. Pick the highest-priority incomplete slice from the guide.
4. Write the slice-selection note.
5. Read only the slice docs, likely code, and likely tests.
6. Implement one vertical behavior change.
7. Add or update focused tests.
8. Update docs/artifacts only if public behavior or artifact shape changed.
9. Run targeted tests.
10. Run broader tests only when schema/planner/artifact behavior changed enough
    to justify it.
11. Update the status ledger.
12. Immediately select the next slice and repeat.

Multi-slice requirement:
Aim to complete several small vertical slices or one substantial slice plus
follow-on hardening. If a chosen slice finishes quickly, continue into the next
slice rather than stopping.

If a slice becomes too large:
- finish the smallest safe vertical subset,
- test it,
- update the ledger,
- continue with either the next subset or the next queue item.

Subagent strategy:
Use subagents only for bounded reconnaissance or review. Require compact output:

```text
Findings:
Files inspected:
Recommended edit:
Risks:
Tests:
```

Subagent constraints:
- no long code excerpts
- no full command output
- no broad repo summaries
- no reading all docs
- no speculative product expansion
- include file paths and line references when relevant

Context-control rules:

- Prefer `rg` and targeted `sed`/`nl` reads.
- Prefer one or two focused files over whole-directory reads.
- Do not open large generated artifacts unless the selected slice requires it.
- Summarize command failures; do not paste full output unless needed to debug.
- For ExUnit failures, keep the relevant assertion, file, and line; omit long
  logs.
- Do not update broad roadmap docs unless implemented behavior changes roadmap
  or maturity status.
- Do not add new feature buckets during implementation goals.
- Do not refactor unrelated files.
- If context gets large, compress into the ledger and continue with narrow
  reads; do not stop solely because context is large.

Product priority order:
Use `docs/autonomous_work_guide.md` as the source of truth. Current default:

1. Typed operational activity and timeline semantics.
2. Resource and communications allocation semantics.
3. Quality gates, readiness, and import eligibility.
4. Branch-local candidate refresh depth.
5. Validation, compatibility, and challenge fixtures.

Definition of done for each slice:

- public behavior exists behind a module/facade or validated artifact contract
- deterministic IDs/order are preserved for fixed inputs
- schema validation exists for new public artifacts when applicable
- focused tests cover normal and failure/edge behavior
- docs/artifacts are updated only where behavior changed
- assumptions, provenance, validation level, and known limits are explicit
- existing V1/V2/V3 behavior remains compatible unless changed deliberately
- status ledger is updated

Verification guidance:

- Start with targeted tests, for example:
  `mix test test/orbital_dynamics/timeline_test.exs`
- Run schema export/lint tests when schema contracts change.
- Run broader `mix test` after broad planner/schema changes or after several
  related slices.
- If Mix fails because of sandbox filesystem-lock issues, record the exact
  failure in the final answer and status ledger, then continue with static
  verification or another independent slice if possible.

Final response:
Keep the final response short:

- slices completed
- key files changed
- tests run
- next suggested slice
- blockers
```
