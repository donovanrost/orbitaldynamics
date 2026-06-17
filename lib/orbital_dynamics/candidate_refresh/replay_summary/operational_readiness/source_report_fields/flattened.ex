defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.Aggregates

  def source_report_fields(source_reports) do
    %{
      "source_report_operational_readiness_contract" =>
        Aggregates.field(source_reports, "contract"),
      "source_report_operational_readiness_count" =>
        Aggregates.identity_count(source_reports, "count"),
      "source_report_operational_readiness_row_count" =>
        Aggregates.identity_count(source_reports, "row_count"),
      "source_report_operational_readiness_paths" =>
        Aggregates.identity_field(source_reports, "paths"),
      "source_report_operational_readiness_readiness_level_counts" =>
        Aggregates.merge_count_maps(source_reports, "readiness_level_counts"),
      "source_report_operational_readiness_import_classification_counts" =>
        Aggregates.merge_count_maps(source_reports, "import_classification_counts"),
      "source_report_operational_readiness_status_counts" =>
        Aggregates.merge_count_maps(source_reports, "status_counts"),
      "source_report_operational_readiness_gate_count" =>
        Aggregates.count(source_reports, "gate_count"),
      "source_report_operational_readiness_passed_gate_count" =>
        Aggregates.count(source_reports, "passed_gate_count"),
      "source_report_operational_readiness_review_gate_count" =>
        Aggregates.count(source_reports, "review_gate_count"),
      "source_report_operational_readiness_analysis_gate_count" =>
        Aggregates.count(source_reports, "analysis_gate_count"),
      "source_report_operational_readiness_analysis_mode_counts" =>
        Aggregates.merge_count_maps(source_reports, "analysis_mode_counts"),
      "source_report_operational_readiness_blocked_gate_count" =>
        Aggregates.count(source_reports, "blocked_gate_count"),
      "source_report_operational_readiness_ready_for_import_count" =>
        Aggregates.count(source_reports, "ready_for_import_count"),
      "source_report_operational_readiness_manifest_review_required_count" =>
        Aggregates.count(source_reports, "manifest_review_required_count"),
      "source_report_operational_readiness_blocked_import_count" =>
        Aggregates.count(source_reports, "blocked_import_count"),
      "source_report_operational_readiness_missing_import_count" =>
        Aggregates.count(source_reports, "missing_import_count"),
      "source_report_operational_readiness_invalid_cadence_import_count" =>
        Aggregates.count(source_reports, "invalid_cadence_import_count"),
      "source_report_operational_readiness_review_required_count" =>
        Aggregates.count(source_reports, "review_required_count"),
      "source_report_operational_readiness_current_freshness_count" =>
        Aggregates.count(source_reports, "current_freshness_count"),
      "source_report_operational_readiness_stale_freshness_count" =>
        Aggregates.count(source_reports, "stale_freshness_count"),
      "source_report_operational_readiness_unknown_freshness_count" =>
        Aggregates.count(source_reports, "unknown_freshness_count"),
      "source_report_operational_readiness_freshness_status_counts" =>
        Aggregates.merge_count_maps(source_reports, "freshness_status_counts"),
      "source_report_operational_readiness_schema_validation_pass_count" =>
        Aggregates.count(source_reports, "schema_validation_pass_count"),
      "source_report_operational_readiness_schema_validation_fail_count" =>
        Aggregates.count(source_reports, "schema_validation_fail_count"),
      "source_report_operational_readiness_schema_validation_error_count" =>
        Aggregates.count(source_reports, "schema_validation_error_count"),
      "source_report_operational_readiness_schema_validation_warning_count" =>
        Aggregates.count(source_reports, "schema_validation_warning_count"),
      "source_report_operational_readiness_schema_validation_remediation_count" =>
        Aggregates.count(source_reports, "schema_validation_remediation_count"),
      "source_report_operational_readiness_schema_validation_status_counts" =>
        Aggregates.merge_count_maps(source_reports, "schema_validation_status_counts"),
      "source_report_operational_readiness_import_status_counts" =>
        Aggregates.merge_count_maps(source_reports, "import_status_counts"),
      "source_report_operational_readiness_cadence_import_status_counts" =>
        Aggregates.merge_count_maps(source_reports, "cadence_import_status_counts"),
      "source_report_operational_readiness_adapter_trust_boundary_declared_count" =>
        Aggregates.count(source_reports, "adapter_trust_boundary_declared_count"),
      "source_report_operational_readiness_adapter_trust_boundary_missing_count" =>
        Aggregates.count(source_reports, "adapter_trust_boundary_missing_count"),
      "source_report_operational_readiness_adapter_trust_boundary_untrusted_count" =>
        Aggregates.count(source_reports, "adapter_trust_boundary_untrusted_count"),
      "source_report_operational_readiness_adapter_boundary_status_counts" =>
        Aggregates.merge_count_maps(source_reports, "adapter_boundary_status_counts"),
      "source_report_operational_readiness_resource_availability_pressure_count" =>
        Aggregates.count(source_reports, "resource_availability_pressure_count"),
      "source_report_operational_readiness_resource_availability_reason_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          "resource_availability_reason_counts"
        ),
      "source_report_operational_readiness_resource_availability_reason_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          "resource_availability_reason_ids"
        ),
      "source_report_operational_readiness_station_availability_reason_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          "station_availability_reason_ids"
        ),
      "source_report_operational_readiness_station_availability_reason_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          "station_availability_reason_counts"
        ),
      "source_report_operational_readiness_unavailable_resource_reason_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          "unavailable_resource_reason_ids"
        ),
      "source_report_operational_readiness_resource_blocking_dimension_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          "resource_blocking_dimension_counts"
        ),
      "source_report_operational_readiness_review_type_counts" =>
        Aggregates.merge_count_maps(source_reports, "review_type_counts"),
      "source_report_operational_readiness_import_action_counts" =>
        Aggregates.merge_count_maps(source_reports, "import_action_counts"),
      "source_report_operational_readiness_source_review_type_counts" =>
        Aggregates.merge_count_maps(source_reports, "source_review_type_counts")
    }
  end
end
