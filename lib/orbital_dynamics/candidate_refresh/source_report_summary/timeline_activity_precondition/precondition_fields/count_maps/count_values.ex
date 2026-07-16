defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.CountMaps.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def status_counts(%{} = summary) do
    summary
    |> RowValues.precondition_status()
    |> precondition_value_counts()
  end

  def blocked_type_counts(%{} = summary) do
    precondition_type_counts(summary, "blocked_precondition_types")
  end

  def review_type_counts(%{} = summary) do
    precondition_type_counts(summary, "review_precondition_types")
  end

  defp precondition_type_counts(%{} = summary, field) do
    summary
    |> RowValues.precondition_types(field)
    |> precondition_value_counts()
  end

  defp precondition_value_counts(values) do
    values
    |> List.wrap()
    |> count_source_report_values()
  end
end
