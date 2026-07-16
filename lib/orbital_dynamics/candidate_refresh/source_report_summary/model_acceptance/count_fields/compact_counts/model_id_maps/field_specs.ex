defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.ModelIdMaps.FieldSpecs do
  @moduledoc false

  @compact_model_id_count_fields [
    "model_ids_by_status",
    "model_ids_by_validation_level",
    "model_ids_by_intended_use"
  ]

  def compact_model_id_count_fields, do: @compact_model_id_count_fields
end
