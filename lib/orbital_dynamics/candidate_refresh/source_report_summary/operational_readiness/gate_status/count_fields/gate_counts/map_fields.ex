defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.GateCounts.MapFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "gate_status_counts" => merged_count_map(reports, "gate_status_counts"),
      "gate_classification_counts" => merged_count_map(reports, "gate_classification_counts")
    }
  end

  defp merged_count_map(reports, field) do
    reports
    |> Enum.map(&count_map(&1, field))
    |> merge_count_maps()
  end

  defp count_map(report, field) do
    case Map.get(report, field) do
      %{} = count_map -> count_map
      _value -> %{}
    end
  end
end
