# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitData TLE metadata inspection extraction.

Status:
Completed and pushed.

Selected boundary:
Extract TLE input normalization, line and catalog validation, checksum
validation, fixed-width numeric parsing, compact-exponential parsing, epoch
conversion, mean-element orbital estimates, altitude classification, metadata
construction, and advertised supported metadata fields into
`OrbitalDynamics.OrbitData.TleMetadata`. Preserve all public OrbitData
inspection, import, export, accepted-state, and capability facades.

Selection evidence:
- Live re-ranking places `orbit_data.ex` at 2,304 lines, the largest eligible
  facade behind Schema, Timeline, MissionPlan.Activity, and the root public
  facade.
- The public TLE inspection clauses at lines 363-384 and their dedicated
  parser/metadata family at lines 527-770 form a self-contained metadata-only
  preflight boundary.
- Accepted-state import routes TLE wrappers through this public facade, while
  no Cartesian state, OPM/OEM, OMM, schema, or export logic depends on the
  private TLE implementation.
- OMM/OPM/OEM KVN parsing, duplicate-field validation, Cartesian accepted-state
  construction, covariance/maneuver handling, public clauses, and artifact
  contracts remain outside this boundary.
- Existing comment/blank-line handling, two/three-line forms, multi-object
  rejection, prefix/catalog/checksum failures, fixed-field offsets, epoch year
  pivot, compact exponent semantics, orbital constants, altitude thresholds,
  provenance text, exact error tuples, and capability metadata must remain
  unchanged.

Implementation:
- Selection was recorded and pushed in `88ff0fb6`.
- Implementation was committed and pushed in `edc3ffee`.
- `orbit_data.ex` moved from 2,304 to 2,016 lines.
- `OrbitalDynamics.OrbitData.TleMetadata` is a 325-line owner reached through
  the public inspection facade and one private OMM mean-element delegate.

Verification:
- Strict warning-clean compilation passed across 3,975 files.
- The focused OrbitData file and adjacent capability, accepted-state schema,
  and validation-policy consumers passed together: 59 tests.
- Exact old/new public inspection/import parity passed for 16 cases covering
  valid two- and three-line forms, comment/blank-line handling, atom-keyed
  source and provenance maps, invalid checksums and catalog numbers, line
  prefixes, multi-object rejection, invalid input and option shapes, wrapped
  TLE imports, shared OMM mean-element estimates, and capability metadata.
- `mix xref callers` reports only the OrbitData facade.
- The removed TLE parser/validation/metadata helpers and facade-owned orbital
  constants are absent apart from the shared mean-element delegate, formatting
  and `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
OrbitData TLE metadata inspection extraction, selected in `88ff0fb6` and
implemented in `edc3ffee`.
`orbit_data.ex` moved from 2,304 to 2,016 lines; the dedicated TLE metadata
owner is 325 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
