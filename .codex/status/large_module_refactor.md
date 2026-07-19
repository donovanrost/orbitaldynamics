# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitData OMM metadata extraction.

Status:
Completed and pushed in `20216348`.

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
- Added `OrbitalDynamics.OrbitData.OmmMetadata` as the owner of supported OMM
  fields, duplicate validation, KVN parsing, required/optional mean elements,
  epoch/center/time handling, preflight regime estimates, option maps,
  provenance, compact output, and invalid-input errors.
- Preserved all OrbitData and root public APIs as capability and inspection
  delegates.
- Removed the inline supported-field list and full OMM parser/builder family
  from the facade.
- `orbit_data.ex` moved from 2,016 to 1,856 lines; the new owner is 286 lines.

Verification:
- Strict focused baseline passed all 37 OrbitData tests.
- Exact old/new public parity passed for nine captured cases: supported fields,
  valid and defaulted OMM, BOM/comments, duplicate and missing fields,
  unsupported center/time system, invalid option maps, and non-binary input.
- Post-extraction verification passed all 37 OrbitData tests.
- Static checks confirm the inline contract and OMM helper family left the
  facade; xref reports only OrbitData as a runtime caller of the owner.
- Strict warning-clean forced compile passed for 3,994 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
OrbitData OMM metadata extraction, selected in `16cee79c` and implemented in
`20216348`.
`orbit_data.ex` moved from 2,016 to 1,856 lines; the dedicated OMM metadata
owner is 286 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `timeline_feedback.ex` is now the largest ordinary eligible facade
at 1,993 lines, followed by ResourceProjection and ContactContention.

Blocked:
No.
