# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff-row construction extraction.

Status:
Implementation published in `80f18ab2`; handoff publication pending.

Completed boundary:
`Timeline.DiffRow.build/5` now owns all four duplicate/add/remove/change row
clauses plus exclusive review, safe-provenance, transition-decision,
activity-context, and duplicate-scope helpers.
`Timeline.DiffRow.put_transition_decision/2` preserves the second captured
facade entry point. `Timeline` retains every public function, including the
unchanged contact/command predicates, and supplies 17 shared callbacks. The
two moved guard constants are mirrored exactly. The facade dropped from 8,564
to 8,077 lines.

Selection and corrections:
Selected in `d8c5c4e7`. Guard-required compile-time constants were corrected in
`b05908d4`; both facade entry points and missed activity/protection callbacks
were corrected in `bbeda85e` before successful compile.

Verification:
- Pre-change and post-change focused Timeline cases: 8/8.
- Full Timeline suite: 127/127.
- Timeline schema-contract suites: 36/36.
- Strict warnings-as-errors compile: 3,717 files.
- Canonical AST equivalence: all 39 moved clauses after normalizing only
  callback boundaries; both mirrored guard constants are exact.
- Both callers and public-definition hash unchanged; format, diff, whitespace,
  ownership, caller, and xref checks clean; xref reports only Timeline.
- Independent review: no code findings. Duplicate/add/remove/change routing,
  protected/executed/blocked semantics, safe provenance, transition decisions,
  projections, callback wiring, public predicates, API, schema shape, order,
  determinism, and ownership are exact. Its constant-count documentation note
  is resolved here.

Behavior/schema changes:
None. No schema-generation boundary changed, so export regeneration was not
required.

Last completed slice:
Timeline diff-row construction extraction, published in `80f18ab2`.

Next candidate:
Remap the reduced Timeline facade, emphasizing transition application and
operational-row classification.

Blocked:
No.
