defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.StationCounts.GateReasonCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.StationCounts.ReasonCountMap

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [merge_count_maps: 1]

  def from_report(report) do
    report
    |> Map.get("gates", [])
    |> Enum.map(&from_context/1)
    |> merge_count_maps()
  end

  defp from_context(%{} = context) do
    station_counts =
      context
      |> Map.get("station_availability_reason_counts")
      |> ReasonCountMap.counts()

    resource_counts =
      context
      |> Map.get("resource_availability_reason_counts")
      |> ReasonCountMap.counts()

    if station_counts in [nil, %{}], do: resource_counts || %{}, else: station_counts
  end

  defp from_context(_context), do: %{}
end
