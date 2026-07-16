defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.CountFields do
  @moduledoc false

  alias __MODULE__.CountMaps

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure,
    as: AllocationStationPressure

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "station_pressure_contact_count" =>
        sum_report_count(reports, &AllocationStationPressure.contact_count/1),
      "station_pressure_review_contact_count" =>
        sum_report_count(reports, &AllocationStationPressure.review_contact_count/1)
    }
    |> Map.merge(CountMaps.fields(reports))
  end
end
