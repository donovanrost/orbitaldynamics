# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitData TLE metadata inspection extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactFilter contact normalization extraction, selected in `4a188222` and
implemented in `2e6869b4`.
`communications/contact_filter.ex` moved from 2,356 to 2,062 lines; the
dedicated contact-normalization owner is 340 lines.

Next candidate:
Implement and verify the selected OrbitData TLE metadata-inspection boundary.

Blocked:
No.
