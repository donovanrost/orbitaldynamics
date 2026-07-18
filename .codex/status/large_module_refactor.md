# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline Cadence-import policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move accepted Cadence-import extraction, invalidity checks, review-context
construction, issue precedence, external-ID/trust-boundary validation, and
invalid-context removal into `Timeline.CadenceImportPolicy`. `Timeline` retains
five private entry points used by row/context construction and operational
action policy. Shared stable-ID validation and invalid-shape encoding are
supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,705 lines. This approximately 80-line,
13-clause cluster has one cohesive import-validation responsibility and no
callers outside the five facade entry points. Moving the internal external-ID,
adapter-context, and trust-boundary helpers keeps issue precedence together.

Planned proof:
- Focused Timeline tests for malformed shape, missing trust boundary, malformed
  external ID, and canonical provider-shaped imports.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 13 moved clauses after normalizing only the
  five facade names and two callback boundaries.
- Format, diff, whitespace, ownership, exactly-five-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline operational action policy extraction, selected in `eea68690`, boundary
corrected in `4d37d6f3`, implemented in `be206e7e`, and handed off in
`660d454a`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity gating and invalid-activity construction.

Blocked:
No.
