defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PressureConflictSummary.StationPressure.ContactIds do
  @moduledoc false

  alias __MODULE__.GroupedContactIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure,
    as: AllocationStationPressure

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_lists: 1
    ]

  def fields(reports) do
    %{
      "station_pressure_contact_ids" =>
        string_list_merge(reports, &AllocationStationPressure.contact_ids/1),
      "station_pressure_review_contact_ids" =>
        string_list_merge(reports, &AllocationStationPressure.review_contact_ids/1)
    }
    |> Map.merge(GroupedContactIds.fields(reports))
  end

  defp string_list_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end
end
