defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(summaries) do
    %{
      "row_count" => sum_report_count(summaries, &RowValues.row_count/1),
      "blocked_precondition_count" =>
        sum_report_count(summaries, &RowValues.precondition_count(&1, "blocked")),
      "review_precondition_count" =>
        sum_report_count(
          summaries,
          &RowValues.precondition_count(&1, "review_required")
        ),
      "precondition_status_counts" => CountMaps.precondition_status_counts(summaries),
      "blocked_precondition_type_counts" => CountMaps.blocked_precondition_type_counts(summaries),
      "review_precondition_type_counts" => CountMaps.review_precondition_type_counts(summaries)
    }
  end
end
