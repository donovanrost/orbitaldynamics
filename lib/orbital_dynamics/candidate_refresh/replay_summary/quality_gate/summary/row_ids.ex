defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary.RowIds do
  @moduledoc false

  def fields(quality_gate_summary) do
    %{
      "review_required_quality_gate_row_ids" =>
        quality_gate_status_row_ids(
          quality_gate_summary,
          "review_required",
          "review_required_quality_gate_row_ids"
        ),
      "blocked_quality_gate_row_ids" =>
        quality_gate_status_row_ids(
          quality_gate_summary,
          "blocked",
          "blocked_quality_gate_row_ids"
        ),
      "ready_quality_gate_row_ids" =>
        quality_gate_status_row_ids(
          quality_gate_summary,
          "passed",
          "ready_quality_gate_row_ids"
        ),
      "analysis_only_quality_gate_row_ids" =>
        quality_gate_status_row_ids(
          quality_gate_summary,
          "analysis_only",
          "analysis_only_quality_gate_row_ids"
        )
    }
  end

  defp quality_gate_status_row_ids(report, status, fallback_field) do
    case Map.get(report, "quality_gate_row_ids_by_status") do
      %{} = row_ids_by_status ->
        quality_gate_summary_list_map_values(row_ids_by_status, status)

      _row_ids_by_status ->
        report
        |> Map.get(fallback_field)
        |> list_value()
    end
  end

  defp quality_gate_summary_list_map_values(%{} = values_by_key, key) do
    values_by_key
    |> Map.get(key)
    |> list_value()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
