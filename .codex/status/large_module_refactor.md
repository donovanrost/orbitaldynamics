# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport station-calendar manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `station_calendar_manifest_row/2` into internal
`CadenceImport.StationCalendarManifestRow.build/3`, injecting only the four
shared facade helpers for review action, adapter status, provider-result value
normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` is 6,481 lines. The station-calendar builder is a 164-line
transformation with 125 projected keys, one facade caller, and only four
shared dependencies.

Current coupling/problem:
The main artifact adapter embeds a large station-calendar and reservation
projection alongside every other source transformation.

Public facade to preserve:
All `CadenceImport` APIs; all station-calendar row keys and value expressions;
approval defaults, constant present adapter status, review action, compaction,
deterministic output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/station_calendar_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 125-key projection; the facade supplies
only four same-purpose callbacks; focused Cadence-import and schema-contract
tests pass; strict warnings-as-errors compile, projection equivalence, public
API checks, and independent review are clean.

Verification gaps:
- Initial implementation compile identified two shared provider-result
  normalization calls omitted from the selection count; this correction is
  published before a successful implementation compile.
- Implementation proof, strict compile, and independent review remain.

Tests run:
- Focused baseline: 100/100.

Behavior/schema changes:
None intended.

Last completed slice:
CadenceImport contact-allocation row builder published as implementation
`0d59c21b` and handoff `28b5ec3d`: focused 100/100, strict 3,678-file compile,
exact 185-entry AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next low-coupling
source-specific manifest-row builder.

Blocked:
No.
