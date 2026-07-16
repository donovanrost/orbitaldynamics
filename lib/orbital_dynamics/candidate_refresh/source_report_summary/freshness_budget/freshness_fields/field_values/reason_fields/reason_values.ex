defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.FreshnessFields.FieldValues.ReasonFields.ReasonValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def stale_reasons(reports) when is_list(reports) do
    Enum.flat_map(reports, &stale_reasons/1)
  end

  def stale_reasons(report) do
    list_value(Map.get(report, "stale_reasons")) ++
      Map.keys(Map.get(report, "stale_reason_counts") || %{})
  end

  def unknown_reasons(reports) when is_list(reports) do
    Enum.flat_map(reports, &unknown_reasons/1)
  end

  def unknown_reasons(report) do
    list_value(Map.get(report, "unknown_reasons")) ++
      Map.keys(Map.get(report, "unknown_reason_counts") || %{})
  end

  def stale_reason_count(report), do: length(stale_reasons(report))
  def unknown_reason_count(report), do: length(unknown_reasons(report))

  def sorted_or_nil(values) do
    case sorted_string_values(values) do
      [] -> nil
      sorted_values -> sorted_values
    end
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
