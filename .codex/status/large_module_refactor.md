# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner station-pressure derivation orchestration extraction.

Status:
Implementation published as `73737ad1`; handoff publication pending.

Selected slice:
Move the private prior/mission station-calendar and mission reservation
review/hold pressure orchestration from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedStationPressureBranches` module with one ordered
`build/2` entry point.

Why this slice:
After the operational-review extraction, `CampaignPlanner` remains the largest
named implementation hotspot at 2,064 lines and 148 private functions. The
selected four-stage block is contiguous station report orchestration behind
dedicated station owners.

Current coupling/problem:
The public planner facade still selects station calendar/reservation reports
and owns provider-contention source-path callbacks despite the station pressure
family already owning branch construction.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_station_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing four-stage
sequence to `DerivedStationPressureBranches.build/2`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused station tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- The full planner directory retains five known baseline failures; none is in
  the selected focused files.
- The full directory was not rerun; focused and file-backed coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  callback, ownership, error-behavior, schema, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,064 lines with 148 private functions.
- Target cluster is 4 ordered pipeline calls and 4 private helpers.
- Baseline focused station family: 9 passed with warnings as errors.
- Post-change focused station family: 9 passed with warnings as errors.
- Strict forced compile: 3,647 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Public `CampaignPlanner` function list matches selection commit `f56e0928`.
  Xref reports the new internal module has only the planner runtime caller.
- Format, new-file whitespace, and `git diff --check` passed. No old selected
  station helper remains in the facade.
- `CampaignPlanner` shrank from 2,064 to 2,023 lines. The new internal station
  orchestration module is 49 lines.
- Independent reviewer reran the 9 focused cases, 7 file-backed cases,
  3,647-file compile, public-def, xref, formatting, diff, and new-file checks;
  results matched primary proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedStationPressureBranches.build/2`. The new internal module owns the
exact prior/mission station-calendar and reservation review/hold report
sequence and source-path callbacks. Implementation published as `73737ad1`.

Last completed slice:
Station-pressure derivation orchestration extraction published as `73737ad1`:
`CampaignPlanner` shrank from 2,064 to 2,023 lines; focused, file-backed, and
compile proof passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.
