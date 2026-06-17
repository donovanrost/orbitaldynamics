defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.ResourceAvailability do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_quality_gate_resource_availability_pressure_count" =>
        source_report_family_count(source_reports, "resource_availability_pressure_count"),
      "source_report_quality_gate_resource_availability_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_availability_reason_counts"
        ),
      "source_report_quality_gate_resource_availability_reason_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "resource_availability_reason_ids"
        ),
      "source_report_quality_gate_station_availability_reason_ids" =>
        source_report_family_merge_string_lists(source_reports, "station_availability_reason_ids"),
      "source_report_quality_gate_station_availability_reason_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_availability_reason_counts"
        ),
      "source_report_quality_gate_unavailable_resource_reason_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "unavailable_resource_reason_ids"
        ),
      "source_report_quality_gate_resource_blocking_dimension_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_blocking_dimension_counts"
        ),
      "source_report_quality_gate_blocked_contact_ids_by_blocking_dimension" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "blocked_contact_ids_by_blocking_dimension"
        ),
      "source_report_quality_gate_blocked_contact_ids_by_spacecraft_id" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "blocked_contact_ids_by_spacecraft_id"
        ),
      "source_report_quality_gate_blocked_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "blocked_contact_ids_by_status"
        ),
      "source_report_quality_gate_source_readiness_report_count" =>
        source_report_family_count(source_reports, "source_readiness_report_count")
    }
  end
end
