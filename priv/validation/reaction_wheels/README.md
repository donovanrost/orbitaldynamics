# Independent wheel numerical reference

Regenerate with `python3 priv/validation/reaction_wheels/generate.py`. Python 3
standard-library code integrates a seven-component state (body-to-inertial
quaternion and three signed rotor momenta) by classical RK4 in body coordinates.
It does not import or execute production code. Inputs are hand-declared in
inputs.json. Production wheel evaluation receives the independently integrated
attitudes as prescribed inputs and evolves inertial total momentum instead.

The gyrostat equation follows angular-momentum balance in rotating axes:
`A hdot = torque_external - I alpha_body - omega_body × (I omega_body + A h)`.
Quaternion kinematics are integrated simultaneously from declared inertial angular
rates and accelerations. Two RK4 resolutions, 1/256 and 1/512 s, must agree within
1e-8 in reported momentum and motor quantities. Outputs are sampled at 1/8 s.

Eight cases cover zero motion, disturbance, stationary external unloading,
principal-axis acceleration, unequal-inertia non-principal rotation, changing-axis
rotation with disturbance and signed/permuted axes, momentum saturation and
motor saturation from gyroscopic coupling. Capacity classifications are sampled
and separated from thresholds; they are not proofs for grazing limits.

`SHA256SUMS` binds generator, inputs and reference. Its digest is pinned in
WheelCheck; changes require deliberate review. Normal verification is offline and
needs no Python runtime. Run `MIX_ENV=test mix orbital_dynamics.mission.verify_wheels
--output-dir tmp/wheel_verification` with a fresh output directory.

The production comparison uses 1 s and 0.25 s steps with fixed absolute tolerances
1e-4 and 1e-5 respectively for Nms/Nm quantities. It reports the discrepancy from
midpoint external-torque integration and reference convergence separately.
Zero-external-torque reference conservation must agree within 1e-8 Nms.
This is finite-case numerical verification, not independent actuator validation,
spacecraft validation or continuous-time feasibility certification.

Background: [MIT Euler-equation notes](https://ocw.mit.edu/courses/16-07-dynamics-fall-2009/5e1d8699338146e5127080b880b906d6_MIT16_07F09_Lec28.pdf).
The reference integrates the extended total momentum including the wheel rotors;
the hardware and motion cases are invented.
