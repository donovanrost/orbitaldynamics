defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.Fallbacks do
  @moduledoc false

  alias __MODULE__.RoutedMaps

  def list(report, field) do
    report
    |> Map.get(field)
    |> list_value()
  end

  def non_passed_ids(report, raw_ids) do
    case list(report, "non_passed_gate_ids") do
      [] -> raw_ids
      ids -> ids
    end
  end

  def ids_by_status(row_ids, report) do
    RoutedMaps.by_status(row_ids, report)
  end

  def ids_by_classification(row_ids, report) do
    RoutedMaps.by_classification(row_ids, report)
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
