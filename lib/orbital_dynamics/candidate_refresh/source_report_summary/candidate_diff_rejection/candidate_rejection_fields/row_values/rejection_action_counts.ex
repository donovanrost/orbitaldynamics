defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.RejectionActionCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.CountValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def rejection_reason_counts(report) do
    case rows(report) do
      [] ->
        Map.get(report, "rejection_reason_counts")

      rows ->
        rows
        |> Enum.flat_map(&Rows.rejection_reasons/1)
        |> count_source_report_values()
    end
  end

  def required_action_counts(report) do
    case rows(report) do
      [] ->
        Map.get(report, "required_operator_action_counts")

      rows ->
        rows
        |> Enum.map(&Rows.required_action/1)
        |> CountValues.count()
    end
  end

  defp rows(report), do: Rows.rows(report)
end
