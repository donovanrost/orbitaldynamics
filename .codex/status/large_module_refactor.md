# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-diff callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 22-function `candidate_diff_contract_callbacks/0` facade bag and
  all callback arguments/wrappers from `CandidateDiffContracts`.
- The family now directly uses primitive, collection, stable-ID,
  collection-aggregation, and candidate-refresh scoped-context modules.
- Preserved `OrbitalDynamics.Schema.validate_artifact/2` and
  `OrbitalDynamics.Schema.validation_report/2`.
- Reduced `schema.ex` from 13,513 to 13,471 lines and candidate-diff contracts
  from 715 to 600 lines.
- Published implementation commit `7e264fb0`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Candidate-refresh schema shard, candidate-diff row/report curated fixtures,
  and schema-export tests: 15 passed, 179 excluded.
- Runtime probes preserved exact derived-count, model-limit, changed-field alias,
  lineage identity, and nested stable-ID diagnostics.
- Full schema export left `schemas/` unchanged.
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref confirms the schema facade is the sole candidate-diff caller and the new
  direct dependency edges are limited to the intended shared modules.
- Formatting, callback-residue checks, and `git diff --check` passed.

Verification gaps:
- Full suite not run; focused contract/fixture/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
Timeline-integrity-evidence callback ownership cleanup. Its five callbacks map
directly to primitive and stable-ID validation, and removing the bag eliminates
another dependency blocking direct activity-context and plan-delta validation.

Blocked:
No.
