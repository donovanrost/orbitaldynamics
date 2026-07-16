defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.TimelinePublication.FieldGroups.ArtifactFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence

  def values(reports) do
    %{
      "publication_ids" => Evidence.string_values(reports, "publication_ids"),
      "source_artifact_ids" => Evidence.string_values(reports, "source_artifact_ids"),
      "supersedes_artifact_ids" => Evidence.string_values(reports, "supersedes_artifact_ids"),
      "downstream_product_ids" => Evidence.string_values(reports, "downstream_product_ids"),
      "invalidated_downstream_product_ids" =>
        Evidence.string_values(reports, "invalidated_downstream_product_ids")
    }
  end
end
