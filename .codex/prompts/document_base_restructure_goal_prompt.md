# `/goal` Prompt: Document Base Restructure

```text
Convert the long-running OrbitalDynamics documentation into a real, navigable
document base. The existing top-level docs have grown into multi-hundred-KB
monoliths that bloat context for every future agent run. The goal of this loop
is purely structural: preserve every fact, but reshape the docs so future goal
prompts can point an agent at a small, targeted file instead of the whole
monolith.

Scope (the problem):
- `docs/complete_feature_set.md` (~7100 lines, ~490 KB) is the master feature
  map. It contains six completeness levels, 22 capability areas, a roadmap, and
  a definition of feature complete.
- `docs/artifact_reference.md` (~6800 lines, ~490 KB) contains canonical
  artifact examples, field families (Mission Activities, Result Artifacts, V1
  Campaign Plan, V2 Repair, V3 Strategy, Policy Bundles, Candidate Refresh) and
  compatibility checks.
- `docs/high_fidelity_mission_planning_feature_set.md` (~2600 lines) and
  `docs/leo_constellation_campaign_planner.md` (~1400 lines) are also
  too large to load wholesale.
- `docs/mission_planning_toolkit_spec.md` is already small and can stay as-is
  or be folded into the new structure if a natural home exists.

Non-goals:
- Do not rewrite content for style, terseness, or "modernization."
- Do not add new features, claims, or capabilities.
- Do not change product direction or roadmap ordering.
- Do not delete information unless it is verbatim-duplicated elsewhere in the
  new structure, and even then keep a single canonical copy.
- Do not touch `lib/`, `test/`, `schemas/`, or runtime code in this loop.
  This is a docs-only restructure.

Target shape (the document base):

Create `docs/` as a tree, with the existing monoliths replaced by directories
of focused files plus a stable index. A reasonable layout, which you may refine
once you have read the source docs:

  docs/
    README.md                          # top-level index for the document base
    feature_set/
      README.md                        # index + executive summary + thesis
      completeness_levels/
        00_transparent_astrodynamics_baseline.md
        01_reproducible_studies.md
        02_useful_leo_analysis.md
        03_campaign_planner_v1.md
        04_rolling_operations_planner_v2.md
        05_strategy_orchestration_planner_v3.md
        06_mature_operational_platform.md
      capability_map/
        01_core_astrodynamics_foundations.md
        02_orbit_data_state_updates_interchange.md
        ... (one file per capability area, numbered as in the source)
      roadmap.md
      definition_of_feature_complete.md
    artifacts/
      README.md                        # index over artifact families
      canonical_examples.md
      field_families/
        mission_activities.md
        result_artifacts.md
        v1_campaign_plan.md
        v2_repair_artifact.md
        v3_strategy_artifact.md
        policy_bundles.md
        candidate_refresh_artifact.md
      compatibility_checks.md
    mission_planning/
      high_fidelity_feature_set.md     # split if natural section breaks exist
      leo_constellation_campaign_planner.md
      toolkit_spec.md

Each leaf file should be self-contained enough to read on its own. Each
directory `README.md` should be a short index (one line per file) plus any
overview prose that genuinely scopes the whole directory. Indexes are
navigation, not summaries — do not paraphrase the leaf content into the index.

Hard rules:

- Preserve every fact from the source docs. The diff at the end should be
  near-zero in *content*, only restructuring.
- Preserve every code block, table, list, and example verbatim.
- Preserve the H1 of each leaf as the original section's heading text.
- Preserve heading anchors people might already link to: where a source
  section had a stable name, the new file's H1 should match.
- After the move, the old monolithic files (`complete_feature_set.md`,
  `artifact_reference.md`, `high_fidelity_mission_planning_feature_set.md`,
  `leo_constellation_campaign_planner.md`) must be deleted in the same
  commit as the new structure, not left as duplicates. `docs/README.md`
  must point readers to where each old top-level section now lives.
- Cross-references between docs must be updated to point at the new paths.
  Search the repo for references to the old filenames (in `README.md`,
  goal prompts under `docs/*_goal_prompt.md`, `lib/`, `test/`, `schemas/`,
  comments) and update them. If a reference points to a specific section,
  it should now point at the specific leaf file.

Working loop:

1. Read `docs/complete_feature_set.md` and `docs/artifact_reference.md` end
   to end first — at least their outlines via grep on `^#{1,3} ` — to confirm
   the section boundaries before committing to a layout.
2. Read the other two long docs and `docs/mission_planning_toolkit_spec.md`
   for the same purpose.
3. Write `docs/README.md` first as a navigation skeleton, even if some leaves
   do not exist yet. This pins the contract.
4. Move sections one at a time, in source-document order, into their new
   leaf files. Use `git mv` only when a whole file is being renamed wholesale;
   otherwise create the new file with the exact source bytes for that section
   and remove that range from the source file in the same commit.
5. After each capability area or artifact family is extracted, run:
     grep -nE '^#{1,3} ' <source-doc>
   to confirm the remaining outline matches what is still pending.
6. When a source monolith is fully extracted, delete it.
7. After all extractions, sweep the repo for references to the old paths
   and update them.
8. Final pass: read `docs/README.md` and every directory `README.md` from
   the top, click-through style, and confirm a reader could find any
   capability area, completeness level, or artifact family without ever
   opening the original monoliths.

Verification at the end:

- `git diff` shows only docs moves, deletions, and link updates. No
  production code changed.
- `wc -l docs/**/*.md` shows no single file above ~1500 lines. Files in the
  500–1200 line range are fine; the goal is "no monolith," not "uniform tiny
  chunks."
- A `grep -r` for each old filename (`complete_feature_set.md`,
  `artifact_reference.md`, etc.) finds no remaining references except inside
  this goal prompt itself and any other historical `docs/*_goal_prompt.md`
  files (those are frozen historical artifacts; leave them alone).
- The top-level `docs/README.md` lists every leaf file directly or through a
  directory index, with one-line descriptions.

Stopping conditions:

- Stop and ask the user only if: (a) the source docs contain genuinely
  duplicated content that cannot be deduped without a judgment call, or
  (b) a section's natural boundary is ambiguous enough that two reasonable
  layouts would produce meaningfully different navigation. Otherwise, make
  the reasonable call and keep going.
- Do not stop after the first extraction. The loop is not done until every
  monolith is gone and the document base is the only way to read these docs.

Short loop prompt to use after the goal is set:

  Continue the document-base restructure. Pick the next un-extracted section
  from the remaining monoliths, move it to its leaf file, update the index,
  delete the now-empty range from the source, and continue until every
  monolith is gone and `docs/README.md` covers the whole document base.
```
