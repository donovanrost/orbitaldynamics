defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.ResourceAvailability.ReasonFields do
  @moduledoc false

  alias __MODULE__.ReasonIds
  alias __MODULE__.StationCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "resource_availability_reason_ids" => ReasonIds.resource_availability(reports),
      "station_availability_reason_ids" => ReasonIds.station_availability(reports),
      "station_availability_reason_counts" =>
        reports
        |> Enum.map(&StationCounts.counts/1)
        |> merge_count_maps(),
      "unavailable_resource_reason_ids" => ReasonIds.unavailable_resource(reports)
    }
  end
end
