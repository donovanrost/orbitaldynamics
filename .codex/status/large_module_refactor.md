# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner mixed readiness score-term expectation repair.

Status:
Selected; implementation pending.

Selected boundary:
Teach the quality-gate score-term assertion to exclude the branch's separately
scored operational-readiness pressure from the generic risk penalty.

Selection evidence:
- The failing branch has one `quality_gate_pressure`, one
  `operational_readiness_pressure`, and one generic `repair_warning`.
- Production assigns `-100` to each specialized pressure term and `-100` only
  to the remaining generic risk, preserving the no-double-counting contract.
- The helper subtracts only quality-gate pressure, so its `-200` expectation is
  stale for this mixed-pressure branch.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Production scoring, public APIs, deterministic artifacts, and
schemas remain unchanged.

Last completed slice:
Candidate-refresh empty refresh-budget ID normalization repair, selected in
`ef64d969` and implemented in `ee7ca527`.

Next candidate:
Implement and verify the mixed-pressure assertion repair, then rerun the
five-file regression gate and broad suite.

Blocked:
No.
