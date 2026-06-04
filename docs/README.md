# OrbitalDynamics Document Base

This directory is a navigable document base for the OrbitalDynamics
mission-planning substrate. It replaces the earlier multi-hundred-KB monoliths
with focused, per-topic files that future agents and readers can load
selectively.

If you previously read `docs/complete_feature_set.md`,
`docs/artifact_reference.md`,
`docs/high_fidelity_mission_planning_feature_set.md`, or
`docs/leo_constellation_campaign_planner.md`, every section of those files
now lives under one of the directories below.

## Top-level sections

- [autonomous_work_guide.md](autonomous_work_guide.md) — start here for
  autonomous implementation loops. It gives a short decision queue, the docs to
  read for each slice, likely code/test entry points, and acceptance criteria.
- [feature_set/](feature_set/README.md) — the OrbitalDynamics feature map.
  Executive summary, product thesis, current capability snapshot, six
  completeness levels, the 22-area capability map, recommended roadmap,
  definition of feature complete, risks, assumptions, open questions, and
  the candidate-artifact appendix.
- [artifacts/](artifacts/README.md) — canonical artifact reference. Examples,
  per-family field references (Mission Activities, Result Artifacts, V1
  Campaign Plan, V2 Repair, V3 Strategy, Policy Bundles, Candidate Refresh),
  and compatibility checks.
- [mission_planning/](mission_planning/README.md) — product-shaped planning
  documents: the LEO constellation campaign planner spec (V1/V2/V3), the
  high-fidelity mission-planning feature set, and the original toolkit spec.

## Conventions

- Each leaf file is self-contained enough to read standalone.
- Each directory has a `README.md` index that lists the leaves with a
  one-line hook. Indexes are navigation, not summaries — they do not
  paraphrase leaf content.
- A few leaves that grew oversized have been split into per-topic sub-files
  under a sibling subdirectory of the same stem. The named `*.md` is then
  the index, and the subdirectory holds the focused sub-files. The directory
  README marks these with a `⇒ subdir` annotation.
- Headings preserved verbatim from the source monoliths. Where a section
  became its own file, its original heading is the file's H1.
- Anchors and link text in cross-references between docs use the new file
  paths.

## Historical `/goal` prompts

The `/goal` prompts that produced the current directory layout and earlier
restructures live under `.codex/prompts/` and remain frozen.
