defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewIssueRows

  def from_rows(rows) do
    errors = SchemaValidationReviewIssueRows.errors(rows)
    warnings = SchemaValidationReviewIssueRows.warnings(rows)
    remediation = SchemaValidationReviewIssueRows.remediation(rows)

    %{
      "schema_contract" => "schema_validation_report.v1",
      "model" => "preserved_schema_validation_review_rows",
      "validation_mode" => SchemaValidationReviewIssueRows.row_value(rows, ["validation_mode"]),
      "validated_contract" =>
        SchemaValidationReviewIssueRows.row_value(rows, ["validated_contract", "subject_id"]),
      "validated_artifact_family" =>
        SchemaValidationReviewIssueRows.row_value(rows, ["validated_artifact_family"]),
      "status" => SchemaValidationReviewIssueRows.status_from_rows(rows),
      "error_count" => length(errors),
      "warning_count" => length(warnings),
      "errors" => errors,
      "warnings" => warnings,
      "artifact_path" => SchemaValidationReviewIssueRows.row_value(rows, ["artifact_path"]),
      "remediation_count" => length(remediation),
      "remediation" => remediation
    }
    |> compact_map()
  end
end
