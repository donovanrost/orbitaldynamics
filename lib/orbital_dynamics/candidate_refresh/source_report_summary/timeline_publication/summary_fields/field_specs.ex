defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.SummaryFields.FieldSpecs do
  @moduledoc false

  @count_fields [
    {"source_summary_model_counts", "model"},
    {"source_summary_schema_contract_counts", "schema_contract"},
    {"publication_status_counts", "publication_status"},
    {"downstream_invalidation_status_counts", "downstream_invalidation_status"},
    {"dependency_impact_status_counts", "dependency_impact_status"},
    {"publication_authority_counts", "publication_authority"},
    {"source_artifact_type_counts", "source_artifact_type"}
  ]

  def count_fields, do: @count_fields
end
