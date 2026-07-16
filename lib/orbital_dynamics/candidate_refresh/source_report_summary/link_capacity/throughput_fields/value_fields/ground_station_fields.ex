defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.ValueFields.GroundStationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report,
    as: ThroughputReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_numeric_maps: 1]

  def fields(reports) do
    %{
      "capacity_adjusted_throughput_mb_by_ground_station" =>
        numeric_map_merge(
          reports,
          &ThroughputReport.numeric_values_by_ground_station/2,
          "capacity_adjusted_throughput_mb"
        ),
      "selected_capacity_adjusted_throughput_mb_by_ground_station" =>
        numeric_map_merge(
          reports,
          &ThroughputReport.numeric_values_by_ground_station/2,
          "selected_capacity_adjusted_throughput_mb"
        ),
      "unused_capacity_adjusted_throughput_mb_by_ground_station" =>
        numeric_map_merge(
          reports,
          &ThroughputReport.numeric_values_by_ground_station/2,
          "unused_capacity_adjusted_throughput_mb"
        )
    }
  end

  defp numeric_map_merge(reports, extractor, field) do
    reports
    |> Enum.map(&extractor.(&1, field))
    |> merge_numeric_maps()
  end
end
