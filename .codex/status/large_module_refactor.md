# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline contact-direction normalization policy extraction.

Status:
Implementation published in `6bc2d557`; focused and broad proof is green.

Selected boundary:
Move activity direction normalization, provider alias resolution, canonical
direction membership, and direction token normalization into
`Timeline.ContactDirectionNormalizationPolicy`. `Timeline` retains the private
activity-normalization and capability-alias entry points plus the two existing
public `normalize_contact_direction/1` clauses. The non-string encoder crosses
the boundary explicitly.

Why this slice:
The extraction moved seven clauses into a 54-line internal module and reduced
Timeline from 6,944 to 6,918 lines. Four facade surfaces preserve the private
activity/capability callers and the two-clause public normalization helper.

Completed proof:
- Focused capability and contact-direction examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,738 files.
- Canonical AST equivalence: all seven moved clauses after normalizing only the
  four facade names and encoder callback.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  name/arity/guards, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline contact-direction normalization policy extraction, selected in
`81c89fc5` and implemented in `6bc2d557`.

Next candidate:
Remap the reduced 6,918-line Timeline facade, emphasizing remaining activity
normalization and lifecycle application.

Blocked:
No.
