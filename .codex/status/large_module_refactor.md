# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-metric calculation policy extraction.

Status:
Implementation published in `7df37151`; focused and broad proof is green.

Selected boundary:
Move numeric replacement/source delta and positive-planned completion-fraction
calculation into `Timeline.ActivityMetricCalculationPolicy`. `Timeline` retains
two private entry points. The boundary has no callbacks, module attributes, or
shared vocabulary arguments.

Why this slice:
The extraction moved four clauses into a 15-line internal module and reduced
Timeline from 6,603 to 6,599 lines. Two private entry points preserve
data-volume, throughput, latency, delivery, thermal, diff, context, and
callback-capture callers while moving numeric delta and completion-fraction
rules out of the facade.

Completed proof:
- Focused data-volume, throughput, thermal, and diff examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,746 files.
- Canonical AST equivalence: all four moved clauses after normalizing only
  the two facade names.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-metric calculation policy extraction, selected in `26915dd1`
and implemented in `7df37151`.

Next candidate:
Remap the reduced 6,599-line Timeline facade, avoiding boundaries whose guard
vocabularies remain shared with Timeline.

Blocked:
No.
