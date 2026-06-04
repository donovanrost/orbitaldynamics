# Product Thesis

OrbitalDynamics should be the mission-analysis and planning engine that can
answer, explain, reproduce, and compare operational plan options for Cadence.
Cadence should own user workflow, approvals, command/contact execution, realized
operations, and durable operational audit trails.

The project should not try to make pure Elixir the fastest floating-point
engine. It should make model boundaries explicit enough that scalar Elixir,
Nx/EXLA, native backends, reference tools, or external services can be compared
and swapped without changing the planning layer. Every generated product should
carry assumptions, provenance, model limits, validation level, and enough
metadata for an operator or downstream system to understand what was trusted and
what was ignored.

