# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline execution-uncertainty context extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move `activity_execution_uncertainty_context/1`, uncertainty-source lookup,
relevance classification, numeric/triplet field normalization, and the exact
uncertainty projection into `Timeline.ExecutionUncertaintyContext.build/2`.
`Timeline` retains every public function plus shared stringify, numeric,
triplet, vector-norm, and compaction helpers behind callbacks.

Why this slice:
After the station-calendar extraction, Timeline remains a 9,343-line facade.
This approximately 85-line cluster owns one artifact concern: declared,
missing, and normalized maneuver execution uncertainty. It has two callers and
focused regression/diff coverage. Keeping numeric parsing and vector math in
the facade preserves their shared use by station-calendar callbacks and avoids
coupling that context to an execution-specific module.

Planned proof:
- Focused Timeline tests covering declared/missing uncertainty, numeric-string
  normalization, and uncertainty-sensitive diffs.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the exact projection and every moved clause
  after normalizing only callback boundaries.
- Format, diff, whitespace, ownership, caller, public-definition, and xref
  checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline station-calendar context extraction, implementation published in
`8d9d6b74` and handoff published in `9d775ccf`.

Next candidate:
Remap the reduced Timeline facade after this slice; command-window context is
the leading smaller candidate.

Blocked:
No.
