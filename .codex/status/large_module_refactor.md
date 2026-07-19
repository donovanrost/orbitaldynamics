# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity station-capacity evidence extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract station-capacity fraction/percent path catalogs, capability metadata,
direct/source-calendar precedence, percent conversion, ambiguous-source
handling, and default fraction into
`OrbitalDynamics.Communications.LinkCapacity.StationCapacity`.
Preserve the existing LinkCapacity public API facade.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 3,113 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  Manifest, ContactAllocation, TimelineFeedback, ContactContention,
  ResourceProjection, StationCalendar, RecommendationRiskContext, and
  OperationalReadiness.
- The selected family is one closed evidence resolver used by throughput
  adjustment and station-availability classification and surfaced verbatim in
  capability/assumption metadata.
- Contact validation, throughput and completion derivation, station
  availability severity, report/summary assembly, downlink requirements,
  approval policy, and relay data paths remain outside this boundary.
- Existing ordered path precedence, numeric/string parsing, percent-to-fraction
  conversion, unique-source requirement, direct-before-source precedence,
  missing/ambiguous default of `1.0`, capability metadata, and deterministic
  output remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing station-capacity precedence and normalization,
throughput behavior, capability metadata, schemas, and deterministic output
will be preserved.

Last completed slice:
Manifest ground-network input extraction, selected in `fe2a7e97` and
implemented in `f99a8866`.
`study/manifest.ex` moved from 3,108 to 3,000 lines; the dedicated
ground-network input owner is 117 lines.

Next candidate:
Implement and verify the selected station-capacity evidence extraction.

Blocked:
No.
