# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport JSON normalization extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract recursive atom-key normalization and JSON-safe value encoding into
`OrbitalDynamics.CadenceImport.JsonNormalization`. Move the complete
`stringify_keys/1` and `encode_json_value/1` clause families while preserving
their two existing private facade call seams as delegates.

Selection evidence:
- `cadence_import.ex` is now 3,554 lines.
- The selected contiguous recursive family spans about 22 lines and serves the
  facade's many atom-key compatibility paths plus unsupported-status encoding.
- The family has one responsibility: convert Elixir-shaped keys and values into
  deterministic JSON-safe data while preserving the distinct behavior of key
  normalization versus general value encoding.
- Dispatch, row construction, capability diagnostics, provider normalization,
  schemas, ordering, and manifest construction remain outside the boundary.

Verification:
Pending: focused atom-key and unsupported-status baselines, exact recursive
normalization matrix, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport import-readiness policy extraction, selected in `a5edf9e8` and
implemented in `27cbfdb9`. `cadence_import.ex` moved from 3,573 to 3,554 lines;
the extracted owner is 29 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after JSON normalization has one production owner.

Blocked:
No.
