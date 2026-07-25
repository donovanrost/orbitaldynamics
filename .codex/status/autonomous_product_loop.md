# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve CandidateRefresh source provenance in repair V2.

Status:
Implemented, reviewed, and verified; ready for scoped publication.

Selection evidence:
- CandidateRefresh carries accepted-state, operational-feedback, run,
  source-report, and run-input provenance that repair previously reduced to a
  compact `provenance.candidate_source` summary.
- Its JSON Schema deeply describes `source_reports` and constrains
  `run_input_sources`, but executable validation previously covered only the
  source-report summaries.
- A two-run audit found planner-generated refresh run IDs used wall-clock study
  start time. Retaining them directly made identical repair artifacts differ;
  checkout revision would also make checked-in artifacts self-referential.

Delivered behavior:
- Repair V2 preserves every non-empty supplied CandidateRefresh provenance map
  losslessly at optional `source_candidate_refresh_provenance`, recursively
  stringifying encodable keys without summarizing or reconstructing values.
- The repair field reuses the CandidateRefresh provenance JSON Schema and
  path-aware executable validation for source-report summaries and
  run-input-source string arrays. CandidateRefresh now enforces the latter at
  its original path too.
- Repair- and strategy-generated refreshes derive run IDs from stable study ID
  plus requested generation time and omit the volatile checkout revision.
  Supplied CandidateRefresh artifacts retain their supplied run ID and Git
  revision unchanged.
- The source map remains artifact-level audit context only. It is not routed to
  operator/Cadence rows and cannot affect matching, scoring, ranking, selection,
  schedule/timeline state, provider/Cadence writes, approvals, commanding, or
  autonomous execution.

Level 6 pillar advanced:
Durable reproducible audit handoffs and schema/version compatibility.

Verification:
- Focused provenance, generated-refresh, schema, and StudyRunner family:
  `44 passed` in 25.6s; the final edited run-ID unit proof also passed alone.
- Adjacent CandidateRefresh/repair schema family: `287 passed` in 127.7s.
- Contact-allocation regression family: `238 passed` in 15.6s.
- Schema lint before and after export: `155` artifacts passed with `0` errors
  and `0` warnings.
- Pre-export full suite: `5142/5145 passed` in 692.3s; the three expected
  failures were the repair schema export plus canonical repair and strategy.
- Two identical canonical repair runs produced the same
  `73a7bf68eaaf0be783a758619cc65a99b13f3e2c2b9794c210b5bb0583e98b4d`
  hash; two identical strategy runs produced the same
  `b9efd194296f5da6955516e4fff16f6ee4d21d0b73c4744619921550a7aeb861`
  hash. Generated nested provenance contained no checkout revision.
- Regenerated all schema exports, the manifest schema, and both canonical
  campaigns. Changed generated files are limited to the repair schema, schema
  bundle, canonical repair, and canonical strategy; the manifest schema stayed
  at `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`.
- Canonical strategy comparison found `31` changed leaves: `26` branch repair
  provenance-map additions and five content-derived identity changes. No score,
  rank, decision, count, schedule, or timeline value changed.
- Checked-in schema export gate: `3 passed` in 52.4s.
- Golden artifact gate: `12 passed` in 39.6s.
- Final full suite: `5147 passed` in 720.6s.
- `mix format --check-formatted` and `git diff --check` passed.

Review:
- Resolution omits absent, empty, or invalid provenance and otherwise retains
  the exact normalized source map. Prebuilt provenance is never scrubbed.
- Path-aware validation preserves all existing source-report checks and adds
  run-input-source list/item checks at exact CandidateRefresh or repair paths.
- Planner-generated refresh provenance is deterministic across repeated repair
  and strategy requests and remains stable across the publishing commit.
- Review/import adapters receive no new provenance field or row; generated
  deltas are contextual audit evidence plus content-derived IDs only.
- The slice does not mutate schedules/timelines, reserve contacts, write
  provider/Cadence state, command activity, grant approval/operator authority,
  or execute autonomously.

Last published slice:
- `500546c1` Preserve V2 source window lineage (`5140 passed`; exact lineage is
  retained and enriches only existing candidate-diff review/Cadence rows).

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
Audit exact CandidateRefresh validation records versus refreshed-window
retention by product value and distinctness.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed mapping,
implementation, review, verification, and publication checks.
