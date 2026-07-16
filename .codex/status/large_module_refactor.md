# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Activity-context callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 17-function activity-context facade bag and all callback
  arguments/wrappers from `ActivityContextContracts`.
- The family now directly uses primitive, collection, stable-ID,
  execution-metric, candidate-refresh, candidate-diff, and
  timeline-integrity-evidence modules.
- Removed the facade's now-unused candidate-refresh scoped-context relay.
- Preserved `OrbitalDynamics.Schema.validate_artifact/2` and
  `OrbitalDynamics.Schema.validation_report/2`.
- Reduced `schema.ex` from 13,460 to 13,427 lines and activity-context contracts
  from 422 to 314 lines.
- Published implementation commit `7aa7802c`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Campaign repair/strategy, timeline report, candidate rejection, curated plan
  delta, and schema-export coverage: 15 passed, 180 excluded.
- Runtime probes preserved exact stable-ID list, non-negative count, numeric
  map, provenance, source-window, candidate-change, and timeline-evidence
  diagnostics.
- Full schema export left `schemas/` unchanged; contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused shared-context/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
Plan-delta callback ownership cleanup. Its formerly blocking activity-context,
candidate-diff, timeline-integrity, and realized-activity dependencies are now
direct, while all remaining helpers already have cohesive owners.

Blocked:
No.
