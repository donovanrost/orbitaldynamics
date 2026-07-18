# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline integrity-count policy extraction.

Status:
Implementation published in `66d1c585`; focused and broad proof is green.

Selected boundary:
Move total timeline-integrity issue counts, unique issue types, issue-type
frequencies, dependency issue counts, and exclusivity issue counts into
`Timeline.IntegrityCountPolicy`; dependency/exclusivity type classifiers become
policy-internal. `Timeline` retains five private entry points; list extraction
and count-map sorting cross the boundary explicitly.

Why this slice:
The extraction moved nine clauses into a 53-line internal module and reduced
Timeline from 6,272 to 6,249 lines. Five private entry points preserve all
report coordinators while missing-count defaults, type flattening, frequency
sorting, map/type guards, and dependency/exclusivity substring classification
now live together.

Completed proof:
- Focused dependency/exclusivity review, public integrity summary, and selected
  transition integrity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,764 files.
- Canonical AST equivalence: all nine moved clauses after normalizing only
  public/private heads, list/sort callbacks, and internal classifier callback
  routing.
- Format, whitespace, ownership, exactly-five-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline integrity-count policy extraction, selected in `75c68200` and
implemented in `66d1c585`.

Next candidate:
Continue remapping the 6,249-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.
