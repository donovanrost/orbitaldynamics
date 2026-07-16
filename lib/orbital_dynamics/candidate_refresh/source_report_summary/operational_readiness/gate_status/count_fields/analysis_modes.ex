defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.AnalysisModes do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def counts(report) do
    report
    |> gate_counts()
    |> case do
      %{} = counts when map_size(counts) > 0 -> counts
      _counts -> report_counts(report)
    end
  end

  defp gate_counts(report) do
    report
    |> Map.get("gates", [])
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.get(&1, "analysis_mode"))
    |> count_source_report_values()
  end

  defp report_counts(report) do
    case Map.get(report, "analysis_mode") do
      value when value in [nil, ""] -> Map.get(report, "analysis_mode_counts", %{})
      value -> %{to_string(value) => 1}
    end
  end
end
