defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportFingerprints.BoundaryFields.FieldSpecs do
  @moduledoc false

  @boundary_fields [
    "trust_boundary",
    "trust_boundaries",
    "provenance",
    "metadata",
    "_source_report_trust_boundary"
  ]

  def boundary_fields, do: @boundary_fields
end
