# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport JSON normalization extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,810 files and warnings as errors.
- Three focused atom-key, execution-report, and unsupported-status tests passed
  with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 9-case direct recursive matrix covered nested atom keys, nulls, preserved
  atom and tuple values during key normalization, map encoding, list atoms,
  tuples, scalar atoms, and scalar passthrough.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both recursive clause families have one
  production implementation behind the preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `json_normalization.ex`.
- Bounded local review found no recursion, clause-order, dispatch, output-shape,
  or null/atom/tuple behavior changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport JSON normalization extraction, selected in `b9b31830` and
implemented in `f6ebf3bf`. `cadence_import.ex` moved from 3,554 to 3,536 lines;
the extracted owner is 28 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after JSON normalization has one production owner.

Blocked:
No.
