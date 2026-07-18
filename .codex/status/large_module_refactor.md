# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-template provenance extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move activity-template context wrapping, provenance validation/field selection,
operational-hint normalization, and number/boolean/string hint insertion into a
dedicated policy. Keep two private Timeline facades for provenance and context,
including the existing activity-precondition callback.

Selection evidence:
- The boundary is 12 adjacent private clauses at Timeline lines 2,618-2,715.
- Provenance has three consumers: operational row construction, activity
  operational-hint context, and the activity-precondition callback; context has
  one valid-activity-context consumer.
- Existing artifact encoding, numeric-value, and boolean policies supply all
  dependencies directly, so the extraction requires no callbacks.
- The extraction should replace roughly 98 helper lines with two thin facades,
  materially reducing the current 5,950-line Timeline.
- Valid activity-context coordination, lifecycle/timing/source/product/resource
  contexts, precondition coordination, public API, and schema remain outside
  the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused and full
Timeline tests, schema-contract tests, canonical AST equivalence, static
ownership/facade/public-definition/xref checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline operational-kind classification extraction, selected in `54c846d6`,
implemented in `c51daf17`, and handed off in `7c79ea45`.

Next candidate:
Implement and verify this selected boundary before remapping the reduced
Timeline facade.

Blocked:
No.
