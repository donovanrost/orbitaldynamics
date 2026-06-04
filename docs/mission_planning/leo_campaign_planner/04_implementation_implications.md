# Implementation Implications

The existing toolkit concepts already line up with this direction:

- `MissionPlan` should become the durable activity timeline product.
- `Activity` should grow toward typed operational activities and resource
  effects.
- `Study` and `StudyRun` should remain the reproducibility boundary.
- `ResultSet` should become the structured artifact Cadence can import or link
  to.
- `EventDetector` should cover contacts, eclipses, target visibility, apsides,
  crossings, and other windows.
- `Constraint` should become the common contract for pass/fail/warning/scored
  checks.
- `Search` should evolve from simple parameter sweeps toward candidate-plan
  generation and ranking.

The most important design rule is that every generated product should carry its
assumptions. Operator confidence comes from knowing what produced a plan, what
it ignored, and how much trust the model deserves.

