defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.SchemaValidation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_schema_validation_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "schema_validation_report",
          "status_counts"
        ),
      "source_report_schema_validation_contract" =>
        source_report_family_field(source_reports, "schema_validation_report", "contract"),
      "source_report_schema_validation_count" =>
        source_report_family_identity_count(source_reports, "schema_validation_report", "count"),
      "source_report_schema_validation_row_count" =>
        source_report_family_identity_count(
          source_reports,
          "schema_validation_report",
          "row_count"
        ),
      "source_report_schema_validation_paths" =>
        source_report_family_identity_field(source_reports, "schema_validation_report", "paths"),
      "source_report_schema_validation_validated_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "schema_validation_report",
          "validated_contract_counts"
        ),
      "source_report_schema_validation_mode_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "schema_validation_report",
          "validation_mode_counts"
        ),
      "source_report_schema_validation_error_count" =>
        source_report_family_count(source_reports, "schema_validation_report", "error_count"),
      "source_report_schema_validation_warning_count" =>
        source_report_family_count(source_reports, "schema_validation_report", "warning_count"),
      "source_report_schema_validation_remediation_count" =>
        source_report_family_count(
          source_reports,
          "schema_validation_report",
          "remediation_count"
        ),
      "source_report_schema_validation_remediation_action_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "schema_validation_report",
          "remediation_action_counts"
        ),
      "source_report_schema_validation_remediation_category_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "schema_validation_report",
          "remediation_category_counts"
        ),
      "source_report_schema_validation_remediation_path_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "schema_validation_report",
          "remediation_path_counts"
        )
    }
  end
end
