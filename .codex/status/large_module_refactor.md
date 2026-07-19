# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest ground-track crossing input extraction.

Status:
Completed and pushed in `03ef30f0`.

Selected boundary:
Extract ground-track crossing request validation, rotation options,
constant/tabular Earth-orientation provider selection, and tabular sample
normalization into
`OrbitalDynamics.Study.Manifest.GroundTrackCrossingInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `manifest.ex` at 3,836 lines, fourth behind Schema,
  Timeline, and MissionPlan.Activity and ahead of ResourceProjection,
  StationCalendar, ContactAllocation, and TimelineFeedback.
- The selected helper family owns one manifest-input responsibility spanning
  crossing shape, rotation configuration, provider selection, and provider
  sample normalization.
- The dedicated input owner can reuse the existing Manifest.InputField owner
  and public environment provider modules without duplicating parsing policy.
- Target parsing, candidate refresh, accepted planning state, run options,
  schema export, file loading, and study execution remain outside this
  boundary.
- Existing public APIs, error tuples, normalized keyword values, provider
  selection, ordering, and exported schema remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,909
  files.
- Focused Manifest coverage passed: 42 tests.
- Adjacent StudyRunner and ground-track event-detector coverage passed: 31
  tests.
- Exact public old/new comparison against selection commit `294e8ca0` passed
  for seven valid/invalid manifest inputs plus exact exported JSON Schema
  equality.
- `mix xref callers` reports only the Manifest facade as a runtime caller of
  the extracted input owner.
- Static ownership checks confirm crossing validation, rotation options,
  provider selection, and tabular sample normalization live in the dedicated
  owner while schema and execution remain in their existing owners.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest ground-track crossing input extraction, selected in `294e8ca0` and
implemented in `03ef30f0`.
`manifest.ex` moved from 3,836 to 3,638 lines; the dedicated input owner is 215
lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
