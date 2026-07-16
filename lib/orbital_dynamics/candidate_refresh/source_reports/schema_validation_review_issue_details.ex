defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewIssueDetails do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewIssueEncoding

  def error_row?(row) do
    row["issue_severity"] in [nil, "", "error"] and
      (row["validation_status"] == "fail" or row["schema_validation_gate_status"] == "fail" or
         row["issue_path"] not in [nil, ""] or is_map(row["source_validation_issue"]))
  end

  def warning_row?(row), do: row["issue_severity"] == "warning"

  def issue_from_row(row) do
    issue =
      case row["source_validation_issue"] do
        %{} = issue -> SchemaValidationReviewIssueEncoding.stringify_keys(issue)
        _issue -> %{}
      end

    issue
    |> Map.put_new("severity", row["issue_severity"])
    |> Map.put_new("path", row["issue_path"])
    |> Map.put_new("message", row["issue_message"])
    |> compact_map()
  end

  def remediation_from_row(row) do
    remediation =
      case row["source_validation_remediation"] do
        %{} = remediation -> SchemaValidationReviewIssueEncoding.stringify_keys(remediation)
        _remediation -> %{}
      end

    remediation
    |> Map.put_new("path", row["issue_path"])
    |> Map.put_new("category", row["remediation_category"])
    |> Map.put_new("action", row["remediation_action"])
    |> Map.put_new("source_message", row["issue_message"])
    |> compact_map()
  end
end
