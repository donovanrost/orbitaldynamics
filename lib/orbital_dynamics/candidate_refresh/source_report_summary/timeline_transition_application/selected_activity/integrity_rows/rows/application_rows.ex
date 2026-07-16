defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows.Rows.ApplicationRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def rows(report) do
    report
    |> ReportShape.application_rows()
    |> Enum.filter(&integrity_context?/1)
    |> Enum.map(&row_from_application_row/1)
  end

  defp integrity_context?(%{} = row) do
    row["selected_timeline_integrity_status"] not in [nil, ""] or
      row["selected_timeline_integrity_issue_count"] not in [nil, ""] or
      List.wrap(row["selected_timeline_integrity_issue_types"]) != [] or
      List.wrap(row["selected_timeline_integrity_issues"]) != []
  end

  defp integrity_context?(_row), do: false

  defp row_from_application_row(row) do
    %{
      "timeline_integrity_status" => Map.get(row, "selected_timeline_integrity_status"),
      "timeline_integrity_issue_count" => Map.get(row, "selected_timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => Map.get(row, "selected_timeline_integrity_issue_types"),
      "timeline_integrity_issues" => Map.get(row, "selected_timeline_integrity_issues"),
      "required_operator_action" => Map.get(row, "required_operator_action")
    }
    |> compact_map()
  end
end
