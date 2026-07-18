# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-field value policy extraction.

Status:
Implementation published in `37b9114f`; focused and broad proof is green.

Selected boundary:
Move top-level/metadata field lookup, string/existing-atom key fallback, and
first numeric, numeric-or-scalar, scalar-string, provider-result-string, and
stable-identifier selection into `Timeline.ActivityFieldValuePolicy`.
`Timeline` retains seven private entry points. Numeric conversion,
provider-result artifact extraction, and stable-ID validation cross the
boundary explicitly.

Why this slice:
The extraction moved 10 clauses into a 106-line internal module and reduced
Timeline from 6,674 to 6,615 lines. Seven private entry points preserve
candidate rejection, activity context, resource, link, dependency,
exclusivity, and publication callers while moving key precedence, metadata
fallback, nil handling, scalar coercion, and stable-ID filtering out of the
facade.

Completed proof:
- Focused activity-context and identity examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,743 files.
- Canonical AST equivalence: all 10 moved clauses after normalizing only the
  seven facade names and three callback boundaries.
- Format, whitespace, ownership, exactly-seven-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-field value policy extraction, selected in `d7da8e84` and
implemented in `37b9114f`.

Next candidate:
Remap the reduced 6,615-line Timeline facade, emphasizing lifecycle state
assembly.

Blocked:
No.
