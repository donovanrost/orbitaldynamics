# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitData OMM metadata extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract CCSDS OMM KVN duplicate validation, parsing, required mean-element
validation, epoch/center/time handling, propagation-regime classification,
preflight orbital estimates, source/provenance normalization, and supported
metadata declaration into `OrbitalDynamics.OrbitData.OmmMetadata`. Preserve all
OrbitData and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `orbit_data.ex` at 2,016 lines, the largest ordinary
  eligible facade.
- OrbitData currently delegates only TLE metadata; the OMM public preflight and
  private parser/builder occupy lines 347-482, while its supported metadata
  contract remains inline in capabilities at lines 124-153.
- The OMM boundary is metadata-only and does not participate in accepted
  Cartesian planning-state construction, OPM/OEM state import/export, or
  maneuver/covariance serialization.
- TLE, simple JSON, OPM, OEM, accepted-state validation, state estimates,
  provenance inheritance, and all public error contracts outside OMM remain
  outside the boundary.
- Exact duplicate handling, comment/BOM parsing, default/version fields,
  required and optional numeric behavior, epoch precision, EARTH-only center,
  time-system validation, regime estimates, option normalization, provenance,
  compact output, and invalid-input errors must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext objective-tradeoff extraction, selected in
`3ebf90d9` and implemented in `2f581923`.
`recommendation_risk_context.ex` moved from 2,016 to 1,893 lines; the dedicated
objective-tradeoff owner is 159 lines.

Next candidate:
Complete the selected OrbitData OMM metadata extraction.

Blocked:
No.
