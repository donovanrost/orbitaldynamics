defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffEncoding

  def summary?(%{} = summary) do
    review_rows = Map.get(summary, "review_rows") || Map.get(summary, :review_rows)
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    is_list(review_rows) and
      (model == "artifact_only_timeline_diff_summary" or
         schema_contract in [nil, "timeline_diff_summary.v1"])
  end

  def summary?(_summary), do: false

  def report_from_summary(%{} = summary) do
    summary = TimelineDiffEncoding.stringify_keys(summary)

    summary
    |> Map.put("rows", Map.get(summary, "review_rows", []))
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
  end
end
