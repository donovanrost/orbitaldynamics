defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.SummaryFields.IdFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def fields(summaries) do
    %{
      "publication_ids" => string_values(summaries, "publication_id"),
      "source_artifact_ids" => string_values(summaries, "source_artifact_id"),
      "supersedes_artifact_ids" => list_values(summaries, "supersedes_artifact_ids"),
      "downstream_product_ids" => list_values(summaries, "downstream_product_ids"),
      "invalidated_downstream_product_ids" =>
        list_values(summaries, "invalidated_downstream_product_ids")
    }
  end

  defp string_values(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field))
    |> sorted_string_values()
  end

  defp list_values(summaries, field) do
    summaries
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end
end
