# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest schema-document extraction.

Status:
Completed and pushed.

Selected boundary:
Extract structural study-manifest JSON Schema assembly, including scenario,
mission-plan, campaign, candidate-refresh, search, Monte Carlo, constraint,
spacecraft, state-vector, ground-network, planning-state, resource, and
operational-feedback schema fragments, into
`OrbitalDynamics.Study.Manifest.SchemaDocument`. Preserve
`OrbitalDynamics.Study.Manifest.json_schema/0`, schema export, field-reference,
lint-report, parsing, and all other public facade behavior.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `study/manifest.ex` at 2,229 lines, the largest
  ordinary eligible facade behind Schema, Timeline, and MissionPlan.Activity.
- The public schema document starts at line 282 and its private structural
  builders occupy lines 395-986, a contiguous responsibility already composed
  from dedicated ActivitySchema and RealizedActivitySchema owners.
- Parsing, semantic validation, scenario construction, metadata assembly,
  execution options, validation-report execution, and file I/O remain outside
  the boundary.
- The facade will pass its authoritative schema version, accepted propagator
  and output names, search objectives, and lint error codes into the owner so
  no public contract constants fork.
- Exact map shape, nested contract embedding, list ordering, compatibility and
  identity policy metadata, JSON export bytes, field-reference output, and lint
  behavior must remain unchanged.

Implementation:
- Selection was recorded and pushed in `4beb22bd`.
- Implementation was committed and pushed in `d80ce4e9`.
- `study/manifest.ex` moved from 2,229 to 1,621 lines.
- `OrbitalDynamics.Study.Manifest.SchemaDocument` is a 632-line owner reached
  through the public facade's unchanged `json_schema/0` entry point.

Verification:
- Strict warning-clean compilation passed across 3,982 files.
- The focused manifest loader, schema export, reference, manifest lint, and
  adjacent schema-lint consumers passed together: 72 tests.
- Exact old/new public parity passed for the complete schema term, encoded
  schema bytes, complete field-reference term, encoded field-reference bytes,
  exported file bytes, and checked-in schema bytes.
- One broader campaign golden-artifact assertion failed identically in an
  isolated pre-extraction worktree at `4beb22bd`; it is unrelated to the schema
  ownership move.
- `mix xref callers` reports only the Study.Manifest facade.
- The facade-owned structural schema builders are absent, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
Study.Manifest schema-document extraction, selected in `4beb22bd` and
implemented in `d80ce4e9`.
`study/manifest.ex` moved from 2,229 to 1,621 lines; the dedicated schema
document owner is 632 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
