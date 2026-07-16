defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.SourceFields.SummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_report_field_values: 2]

  def contract(states) do
    states
    |> Enum.map(&Map.get(&1, "schema_contract"))
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      _contracts -> nil
    end
  end

  def model_counts(states) do
    states
    |> count_report_field_values("model")
    |> non_empty_map()
  end

  def schema_contract_counts(states) do
    states
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
