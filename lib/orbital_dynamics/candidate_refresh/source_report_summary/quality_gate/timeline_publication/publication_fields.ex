defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication.PublicationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication.FieldGroups

  def fields(reports) do
    %{
      "publication_status_counts" => FieldGroups.count_map(reports, "publication_status_counts"),
      "publication_authority_counts" =>
        FieldGroups.count_map(reports, "publication_authority_counts"),
      "timeline_publication_source_artifact_type_counts" =>
        FieldGroups.count_map(reports, "source_artifact_type_counts"),
      "publication_ids" => FieldGroups.string_values(reports, "publication_ids"),
      "source_artifact_ids" => FieldGroups.string_values(reports, "source_artifact_ids"),
      "supersedes_artifact_ids" => FieldGroups.string_values(reports, "supersedes_artifact_ids"),
      "downstream_product_ids" => FieldGroups.string_values(reports, "downstream_product_ids"),
      "invalidated_downstream_product_ids" =>
        FieldGroups.string_values(reports, "invalidated_downstream_product_ids")
    }
  end
end
