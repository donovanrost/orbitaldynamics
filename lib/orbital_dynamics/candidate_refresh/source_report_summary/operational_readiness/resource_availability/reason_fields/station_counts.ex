defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.StationCounts do
  @moduledoc false

  alias __MODULE__.GateReasonCounts
  alias __MODULE__.ReasonCountMap
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence

  def filter_reason_ids(values), do: ReasonCountMap.filter_reason_ids(values)

  def counts(report) do
    [
      evidence_reason_counts(report, "station_availability_reason_counts"),
      evidence_reason_counts(report, "resource_availability_reason_counts"),
      gate_station_reason_counts(report)
    ]
    |> Enum.find(%{}, &(&1 not in [nil, %{}]))
  end

  defp evidence_reason_counts(report, field) do
    report
    |> Evidence.count_map(field)
    |> ReasonCountMap.counts()
  end

  defp gate_station_reason_counts(report), do: GateReasonCounts.from_report(report)
end
