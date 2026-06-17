defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Aggregation

  def source_report_throughput_fields(source_reports) do
    %{
      "source_report_link_capacity_selected_shortfall_row_count" =>
        source_report_family_count(source_reports, "selected_shortfall_row_count"),
      "source_report_link_capacity_actual_shortfall_row_count" =>
        source_report_family_count(source_reports, "actual_shortfall_row_count"),
      "source_report_link_capacity_actual_throughput_row_count" =>
        source_report_family_count(source_reports, "actual_throughput_row_count"),
      "source_report_link_capacity_capacity_adjusted_throughput_row_count" =>
        source_report_family_count(source_reports, "capacity_adjusted_throughput_row_count"),
      "source_report_link_capacity_capacity_adjusted_throughput_mb_total" =>
        source_report_family_numeric_sum(source_reports, "capacity_adjusted_throughput_mb_total"),
      "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_total" =>
        source_report_family_numeric_sum(
          source_reports,
          "selected_capacity_adjusted_throughput_mb_total"
        ),
      "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_total" =>
        source_report_family_numeric_sum(
          source_reports,
          "unused_capacity_adjusted_throughput_mb_total"
        ),
      "source_report_link_capacity_capacity_adjusted_throughput_mb_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_adjusted_throughput_mb_by_ground_station"
        ),
      "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "selected_capacity_adjusted_throughput_mb_by_ground_station"
        ),
      "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_by_ground_station" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "unused_capacity_adjusted_throughput_mb_by_ground_station"
        ),
      "source_report_link_capacity_capacity_adjusted_throughput_mb_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "capacity_adjusted_throughput_mb_by_direction"
        ),
      "source_report_link_capacity_selected_capacity_adjusted_throughput_mb_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "selected_capacity_adjusted_throughput_mb_by_direction"
        ),
      "source_report_link_capacity_unused_capacity_adjusted_throughput_mb_by_direction" =>
        source_report_family_merge_numeric_maps(
          source_reports,
          "unused_capacity_adjusted_throughput_mb_by_direction"
        ),
      "source_report_link_capacity_ground_station_counts" =>
        source_report_family_merge_count_maps(source_reports, "ground_station_counts"),
      "source_report_link_capacity_spacecraft_counts" =>
        source_report_family_merge_count_maps(source_reports, "spacecraft_counts"),
      "source_report_link_capacity_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_link_capacity_directions" =>
        source_report_family_field(source_reports, "directions")
    }
  end
end
