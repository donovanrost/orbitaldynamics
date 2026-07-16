defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffSummaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffReplayDetailFields

  def from_source_row(%{} = source_row) do
    %{
      "schema_contract" => "timeline_publication_summary.v1",
      "model" => "artifact_only_timeline_publication_summary",
      "validation_level" => "artifact_contract",
      "source" => source_row["source_artifact_type"],
      "publication_id" => source_row["publication_id"],
      "publication_sequence" => source_row["publication_sequence"],
      "publication_status" => source_row["publication_status"],
      "downstream_invalidation_status" => source_row["downstream_invalidation_status"],
      "publication_authority" => source_row["publication_authority"],
      "source_artifact_id" => source_row["source_artifact_id"],
      "source_artifact_type" => source_row["source_artifact_type"],
      "supersedes_artifact_ids" => source_row["supersedes_artifact_ids"],
      "downstream_product_ids" => source_row["downstream_product_ids"],
      "dependency_impact_status" => source_row["dependency_impact_status"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "notification_delivery" => "host_system_owned",
        "publication_authority" => source_row["publication_authority"],
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => OrbitalDynamics.Timeline.model_limits()
    }
    |> Map.merge(TimelinePublicationHandoffReplayDetailFields.from_source_row(source_row))
  end
end
