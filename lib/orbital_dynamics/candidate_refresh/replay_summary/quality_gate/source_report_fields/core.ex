defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.Core do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_quality_gate_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_quality_gate_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_quality_gate_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_quality_gate_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_quality_gate_readiness_level_counts" =>
        source_report_family_merge_count_maps(source_reports, "readiness_level_counts"),
      "source_report_quality_gate_import_classification_counts" =>
        source_report_family_merge_count_maps(source_reports, "import_classification_counts"),
      "source_report_quality_gate_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "status_counts"),
      "source_report_quality_gate_gate_count" =>
        source_report_family_count(source_reports, "gate_count"),
      "source_report_quality_gate_passed_gate_count" =>
        source_report_family_count(source_reports, "passed_gate_count"),
      "source_report_quality_gate_review_gate_count" =>
        source_report_family_count(source_reports, "review_gate_count"),
      "source_report_quality_gate_analysis_gate_count" =>
        source_report_family_count(source_reports, "analysis_gate_count"),
      "source_report_quality_gate_analysis_mode_counts" =>
        source_report_family_merge_count_maps(source_reports, "analysis_mode_counts"),
      "source_report_quality_gate_blocked_gate_count" =>
        source_report_family_count(source_reports, "blocked_gate_count"),
      "source_report_quality_gate_gate_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "gate_status_counts"),
      "source_report_quality_gate_gate_classification_counts" =>
        source_report_family_merge_count_maps(source_reports, "gate_classification_counts"),
      "source_report_quality_gate_ready_for_import_count" =>
        source_report_family_count(source_reports, "ready_for_import_count"),
      "source_report_quality_gate_manifest_review_required_count" =>
        source_report_family_count(source_reports, "manifest_review_required_count"),
      "source_report_quality_gate_blocked_import_count" =>
        source_report_family_count(source_reports, "blocked_import_count"),
      "source_report_quality_gate_missing_import_count" =>
        source_report_family_count(source_reports, "missing_import_count"),
      "source_report_quality_gate_invalid_cadence_import_count" =>
        source_report_family_count(source_reports, "invalid_cadence_import_count"),
      "source_report_quality_gate_freshness_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "freshness_status_counts"),
      "source_report_quality_gate_freshness_status_ids" =>
        source_report_family_merge_string_lists(source_reports, "freshness_status_ids"),
      "source_report_quality_gate_schema_validation_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "schema_validation_status_counts"),
      "source_report_quality_gate_schema_validation_status_ids" =>
        source_report_family_merge_string_lists(source_reports, "schema_validation_status_ids"),
      "source_report_quality_gate_failed_schema_validation_quality_gate_row_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "failed_schema_validation_quality_gate_row_ids"
        ),
      "source_report_quality_gate_schema_validation_gate_ids" =>
        source_report_family_merge_string_lists(source_reports, "schema_validation_gate_ids"),
      "source_report_quality_gate_import_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "import_status_counts"),
      "source_report_quality_gate_import_status_ids" =>
        source_report_family_merge_string_lists(source_reports, "import_status_ids"),
      "source_report_quality_gate_cadence_import_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "cadence_import_status_counts"),
      "source_report_quality_gate_cadence_import_status_ids" =>
        source_report_family_merge_string_lists(source_reports, "cadence_import_status_ids"),
      "source_report_quality_gate_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_quality_gate_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_quality_gate_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts"),
      "source_report_quality_gate_quality_gate_row_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "quality_gate_row_ids_by_status"
        ),
      "source_report_quality_gate_quality_gate_ids_by_status" =>
        source_report_family_merge_string_list_maps(source_reports, "quality_gate_ids_by_status"),
      "source_report_quality_gate_review_required_quality_gate_row_ids" =>
        source_report_quality_gate_status_row_ids(
          source_reports,
          "review_required",
          "review_required_quality_gate_row_ids"
        ),
      "source_report_quality_gate_blocked_quality_gate_row_ids" =>
        source_report_quality_gate_status_row_ids(
          source_reports,
          "blocked",
          "blocked_quality_gate_row_ids"
        ),
      "source_report_quality_gate_ready_quality_gate_row_ids" =>
        source_report_quality_gate_status_row_ids(
          source_reports,
          "passed",
          "ready_quality_gate_row_ids"
        ),
      "source_report_quality_gate_analysis_only_quality_gate_row_ids" =>
        source_report_quality_gate_status_row_ids(
          source_reports,
          "analysis_only",
          "analysis_only_quality_gate_row_ids"
        ),
      "source_report_quality_gate_stale_or_unknown_freshness_quality_gate_row_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "stale_or_unknown_freshness_quality_gate_row_ids"
        ),
      "source_report_quality_gate_import_preparation_quality_gate_row_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "import_preparation_quality_gate_row_ids"
        ),
      "source_report_quality_gate_blocked_import_quality_gate_row_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "blocked_import_quality_gate_row_ids"
        ),
      "source_report_quality_gate_import_readiness_gate_ids" =>
        source_report_family_merge_string_lists(source_reports, "import_readiness_gate_ids"),
      "source_report_quality_gate_adapter_boundary_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "adapter_boundary_status_counts")
    }
  end
end
