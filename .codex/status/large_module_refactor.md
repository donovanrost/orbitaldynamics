# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity relationship policy extraction.

Status:
Implementation published in `374151ea`; focused and broad proof is green.

Selected boundary:
Move dependency and exclusivity activity/timeline ID field selection, explicit
versus fallback precedence, and duplicate-reference selection into
`Timeline.ActivityRelationshipPolicy`. `Timeline` retains eight private entry
points. Field lookup and general/map-only normalize/duplicate operations cross
the boundary explicitly.

Why this slice:
The extraction moved eight clauses into a 127-line internal module and reduced
Timeline from 6,568 to 6,532 lines. Eight private entry points preserve
integrity, diff, transition, and publication callers while moving dependency
and exclusivity aliases, explicit/fallback precedence, map-only selection, and
duplicate-reference routing out of the facade.

Completed proof:
- Focused scalar, map, fallback, malformed, duplicate, and transition-handoff
  relationship examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,748 files.
- Canonical AST equivalence: all eight moved clauses after normalizing only
  the eight facade names and five callback boundaries.
- Format, whitespace, ownership, exactly-eight-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity relationship policy extraction, selected in `3fdbecd8` and
implemented in `374151ea`.

Next candidate:
Remap the reduced 6,532-line Timeline facade, avoiding boundaries whose guard
vocabularies remain shared with Timeline.

Blocked:
No.
