defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusValues.StatusMaps do
  @moduledoc false

  def gate_ids_by_status(report) do
    cond do
      is_map(Map.get(report, "quality_gate_ids_by_status")) ->
        Map.get(report, "quality_gate_ids_by_status")

      is_map(Map.get(report, "gate_ids_by_status")) ->
        Map.get(report, "gate_ids_by_status")

      true ->
        nil
    end
  end

  def row_ids_by_status(report) do
    case Map.get(report, "quality_gate_row_ids_by_status") do
      %{} = row_ids_by_status -> row_ids_by_status
      _row_ids_by_status -> nil
    end
  end

  def values(%{} = list_map, key) do
    list_map
    |> Map.get(key)
    |> list_value()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
