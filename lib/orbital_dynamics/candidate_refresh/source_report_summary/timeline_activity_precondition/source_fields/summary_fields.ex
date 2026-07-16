defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.SourceFields.SummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_report_field_values: 2]

  def contract(summaries) do
    summaries
    |> Enum.map(&Map.get(&1, "schema_contract"))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "timeline_activity_precondition_summary.v1"
    end
  end

  def model_counts(summaries) do
    summaries
    |> count_report_field_values("model")
    |> non_empty_map()
  end

  def schema_contract_counts(summaries) do
    summaries
    |> count_report_field_values("schema_contract")
    |> non_empty_map()
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
