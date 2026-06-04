# Assumptions

- The first mature operational target is LEO constellation campaign planning.
- Cadence remains the owner of operator UI, approvals, scheduling, command and
  contact execution, realized operations, and durable operational audit trails.
- OrbitalDynamics owns planning inputs, propagation, event detection, search,
  constraints, branch comparison, model assumptions, and generated artifacts.
- JSON manifests and artifacts remain the primary interoperability surface until
  there is a stronger reason for another transport.
- External orbit products and Cadence-sourced state updates are inputs to the
  planner, not proof that OrbitalDynamics owns operational orbit determination.
- Validation and reproducibility are more important than maximizing numerical
  sophistication early.

