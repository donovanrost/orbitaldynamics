defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.ReasonIds.Values do
  @moduledoc false

  alias __MODULE__.ReportReasonIds
  alias __MODULE__.UnavailableReasons
  alias __MODULE__.ValueList

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields.StationCounts

  def resource_availability(reports) do
    reports
    |> Enum.flat_map(&ReportReasonIds.values(&1, "resource_availability_reason_ids"))
    |> ValueList.sorted_non_empty()
  end

  def station_availability(reports) do
    reports
    |> Enum.flat_map(&station_reason_ids/1)
    |> ValueList.sorted_non_empty()
  end

  def unavailable_resource(reports) do
    reports
    |> Enum.flat_map(&UnavailableReasons.values/1)
    |> ValueList.sorted_non_empty()
  end

  defp station_reason_ids(report) do
    report
    |> ReportReasonIds.values("station_availability_reason_ids")
    |> StationCounts.filter_reason_ids()
  end
end
