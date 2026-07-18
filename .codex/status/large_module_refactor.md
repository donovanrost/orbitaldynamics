# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline provider-result policy extraction.

Status:
Implementation published in `6778bbcd`; focused and broad proof is green.

Selected boundary:
Move provider execution failure reasons and the complete provider-result
flattening, failure/success token classification, and artifact serialization
cluster into `Timeline.ProviderResult`. `Timeline` retains three private facade
entry points for failure reason, failure predicate, and artifact value. The
shared ordered provider-result map-key list remains Timeline-owned for
capabilities and is supplied as selection data.

Why this slice:
The extraction moved 25 clauses into a 174-line internal module and reduced
Timeline from 8,077 to 7,930 lines. The three facade entry points preserve all
existing callers, while the shared key list remains with the capabilities
surface.

Completed proof:
- Focused provider-result examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,718 files.
- Canonical AST equivalence: all 25 moved clauses after normalizing only facade
  names and the shared key-list data argument.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public definitions, and xref checks passed.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline provider-result policy extraction, selected in `63d6d709` and
implemented in `6778bbcd`.

Next candidate:
Remap the reduced 7,930-line Timeline facade, emphasizing operational action
classification and transition application.

Blocked:
No.
