defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaries

  def operator_review_summaries(rows, summary?) when is_function(summary?, 1) do
    summaries(rows, summary?, &operator_review_row?/1)
  end

  def cadence_import_summaries(rows, summary?) when is_function(summary?, 1) do
    summaries(rows, summary?, &cadence_import_row?/1)
  end

  defp summaries(rows, summary?, row?) do
    rows
    |> Enum.map(&TimelineActivityPreconditionReviewImportSummaries.stringify_keys/1)
    |> Enum.filter(row?)
    |> Enum.map(
      &TimelineActivityPreconditionReviewImportSummaries.summary_from_review_or_import_row(
        &1,
        summary?
      )
    )
    |> Enum.reject(&is_nil/1)
  end

  defp operator_review_row?(row) do
    row["review_type"] == "timeline_activity_precondition_review"
  end

  defp cadence_import_row?(row) do
    row["source_review_type"] == "timeline_activity_precondition_review" or
      row["import_action"] == "review_timeline_precondition"
  end
end
