defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPreconditionSummaryFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaryRowFields

  def summary(source, rows, artifact) do
    %{
      "schema_contract" => "timeline_activity_precondition_summary.v1",
      "model" => "artifact_only_timeline_activity_precondition_summary",
      "source" => source,
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id")
    }
    |> Map.merge(TimelineActivityPreconditionReviewImportPreconditionSummaryFields.fields(rows))
    |> Map.merge(TimelineActivityPreconditionReviewImportSummaryRowFields.fields(rows, artifact))
    |> compact_map()
  end
end
