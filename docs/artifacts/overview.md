# Artifact Reference

This project treats JSON manifests and generated JSON artifacts as the current
integration surface. The tables below point to the checked-in examples that are
intended to stay reviewable by humans and lintable by tooling.

The exported JSON Schemas are compatibility documents for required top-level
fields, coarse property types, and targeted nested surfaces where the artifact
shape has stabilized. Executable semantic validation still lives in
`OrbitalDynamics.Schema` and `OrbitalDynamics.Study.Manifest`.
`mix orbital_dynamics.schema.lint --all` infers any declared
`schema_contract` that is registered as an executable contract. The checked-in
`study_results/*.json` artifact set is fully covered by directory-wide schema
lint, with no skipped JSON fixtures.

