# Major Risks and Design Principles

- Keep assumptions auditable. Every artifact should explain model limits rather
  than imply precision it does not have.
- Separate analysis capability from operational product capability. A correct
  propagator is not by itself a usable campaign planner.
- Treat current resource and communications models as thin summaries until real
  simulation or calibration exists.
- Do not broaden Cadence integration into direct workflow ownership inside this
  repository.
- Let validation levels govern trust. Educational, analysis, and validated
  models should be distinguishable in artifacts and docs.
- Preserve deterministic ordering, generated ID stability, and seed manifests.
- Keep optimizer outputs explainable; opaque scores are not acceptable
  operational products.
- Treat external inputs as a trust boundary. Imported states, manifests,
  ephemerides, and feedback snapshots need schema validation and provenance.
- Promote mission-state-to-candidate refresh to a first-class capability before
  claiming mature rolling orchestration.
- Avoid making Nx or EXLA claims from small workloads alone. Backends should be
  selected from evidence and capability fit.
- Prefer typed domain concepts when artifact-map conventions become shared
  contracts.
- Expand beyond LEO only after LEO operations are coherent enough to expose the
  right abstractions.

