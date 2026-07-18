# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity operational-hint context extraction.

Status:
Complete and published.

Selected boundary:
Move activity operational-hint context construction and direct-value/template
fallback resolution into one dedicated module. Keep private Timeline facades
for the context builder and the three operational-row value consumers, and
route field lookup, numeric/boolean conversion, template provenance, and
compaction directly through existing policies. Remove the shared
`first_present_value/2` and `boolean_value/1` Timeline facades because strict
compile confirmed the moved fallback logic owned their only remaining callers.

Selection evidence:
- The boundary owns setup/cooldown duration plus telemetry-confirmation
  requirement/status resolution.
- Direct activity or metadata values retain precedence over normalized activity
  template operational hints.
- The context builder has one valid-context consumer; the three value helpers
  also serve the operational-row builder.
- The initial strict compile proved `first_present_value/2` and
  `boolean_value/1` became unused after the move; repo search confirmed no other
  Timeline callers.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,467-line Timeline while
  preserving all four private coordinator seams.
- Activity-template normalization, timing, command windows, lifecycle
  decisions, broad context coordination, public API, and schema remain outside
  the boundary.

Verification:
- Selection published in `37156e81`; corrected helper ownership published in
  `d5b82292`; implementation published in `3f72fc39`.
- Focused baseline and post-change operational-hint coverage: 1 passed.
- Strict warnings-as-errors compile: 3,797 files compiled.
- Full Timeline suite: 127 passed.
- Operational Timeline schema contracts: 36 passed.
- Canonical AST comparison: all five moved functions equivalent after
  normalizing only facade names and the direct provenance-policy adapter.
- Static checks confirmed unchanged public API, four private facades with exact
  consumer counts, removal of the moved/dead helpers, Timeline-only runtime
  ownership, no temporary checker, and clean formatting/diff.
- Independent review: clean, with no production-code findings.
- Timeline is 5,408 lines; the extracted module is 88 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity operational-hint context extraction, selected in `37156e81`,
corrected in `d5b82292`, and implemented in `3f72fc39`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
