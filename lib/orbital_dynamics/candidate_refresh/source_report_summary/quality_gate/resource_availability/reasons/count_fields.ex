defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.CountFields do
  @moduledoc false

  alias __MODULE__.RowCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "resource_availability_pressure_count" =>
        sum_report_count(reports, &RowCounts.resource_availability_pressure_count/1),
      "resource_availability_reason_counts" =>
        reports
        |> Enum.map(&RowCounts.resource_availability_reason_counts/1)
        |> merge_count_maps(),
      "station_availability_reason_counts" =>
        reports
        |> Enum.map(&RowCounts.station_availability_reason_counts/1)
        |> merge_count_maps(),
      "resource_blocking_dimension_counts" =>
        reports
        |> Enum.map(&RowCounts.resource_blocking_dimension_counts/1)
        |> merge_count_maps()
    }
  end
end
