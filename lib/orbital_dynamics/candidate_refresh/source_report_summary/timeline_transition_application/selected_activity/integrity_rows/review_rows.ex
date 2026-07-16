defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows.ReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows.Rows

  def review?(%{} = row) do
    NormalizedToken.value(Map.get(row, "timeline_integrity_status")) ==
      "review_required" or
      Rows.summary_integer(row, "timeline_integrity_issue_count") > 0 or
      List.wrap(Map.get(row, "timeline_integrity_issue_types")) != [] or
      Map.get(row, "required_operator_action") == "review_timeline_integrity"
  end

  def review?(_row), do: false
end
