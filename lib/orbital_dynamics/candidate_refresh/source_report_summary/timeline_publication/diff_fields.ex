defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelinePublication.DiffFields do
  @moduledoc false

  alias __MODULE__.ChangeFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(summaries) do
    %{
      "timeline_diff_row_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "timeline_diff_row_count")),
      "timeline_diff_changed_count" =>
        sum_report_count(summaries, &numeric_report_count(&1, "timeline_diff_changed_count")),
      "timeline_diff_review_required_count" =>
        sum_report_count(
          summaries,
          &numeric_report_count(&1, "timeline_diff_review_required_count")
        )
    }
    |> Map.merge(ChangeFields.fields(summaries))
  end
end
