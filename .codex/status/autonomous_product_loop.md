# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Validate repair replacement-ranking arithmetic.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Reject internally inconsistent V2 replacement-ranking score arithmetic,
semantic-diff priority, pressure evidence, and row order.

Why this slice:
The nested contract validated ranking shape, IDs, counts, ranks, and selection,
but still accepted impossible score sums, inverted semantic-diff priority,
nonzero pressure without evidence, and misordered alternatives.

Selection note:
The live audit found no safer new candidate pressure to promote: contact and
resource filter rows are already hard exclusions; reduced allocation/calendar
evidence is already scored; and remaining counteroffer/reservation sources lack
consistent replacement-candidate identity or replay through existing paths.

Level 6 pillar:
Versioned compatibility and explainable operational-planning handoffs.

Implemented:
- Each row's ranking score must equal candidate value plus all emitted penalty
  terms within an absolute `1.0e-9` tolerance.
- Semantic candidate-diff matches require priority `0`; unmatched alternatives
  require priority `1`.
- Nonzero station, link, and resource pressure penalties require their source
  list, positive shortfall, or nonempty risk indicators respectively.
- Zero-weight pressured evidence remains valid, preserving intentional policy
  calibration.
- Rows must remain priority-ascending and score-descending within a priority.

Docs changed:
- `docs/feature_set/capability_map/13_v2_rolling_repair.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Ranking/exact/planner focused tests: `17 passed`.
- Schema area: `188 passed`.
- Campaign-planner area: `754 passed`.
- Full suite with `--timeout 120000`: `3513 passed`.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Checks are runtime cross-field invariants over the published nested schema;
  no planner scoring behavior or generated export changed.
- Arithmetic and ordering checks skip malformed numeric shapes already handled
  by field-type validation, avoiding secondary validator crashes.
- Evidence checks trigger only for nonzero numeric penalties, so a known
  pressure with a policy weight of zero remains representable.
- Mutation tests independently pin score, priority, evidence, and order errors;
  real pressured outputs and the checked-in nominal fixture remain valid.

Previous published slice:
- `23f586f9` Validate repair replacement rankings (`3512 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth where evidence is genuinely
  candidate-specific.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, and mechanical publish checks.
