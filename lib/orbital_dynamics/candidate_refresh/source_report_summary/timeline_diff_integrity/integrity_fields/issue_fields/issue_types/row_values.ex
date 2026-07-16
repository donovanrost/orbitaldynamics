defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.IssueTypes.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_field_values: 2]

  def issue_types(row) do
    row
    |> Map.get("timeline_integrity_issues", [])
    |> case do
      issues when is_list(issues) and issues != [] ->
        issues
        |> Enum.map(&EncodedValue.stringify_keys/1)
        |> Enum.flat_map(&source_field_values(&1, "type"))

      _issues ->
        source_field_values(row, "timeline_integrity_issue_types")
    end
  end
end
