# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest schema-document extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention capacity-demand extraction, selected in `ab0e2883` and
implemented in `c7c37b01`.
`communications/contact_contention.ex` moved from 2,242 to 1,978 lines; the
dedicated capacity-demand owner is 317 lines.

Next candidate:
Complete the selected Study.Manifest schema-document extraction.

Blocked:
No.
