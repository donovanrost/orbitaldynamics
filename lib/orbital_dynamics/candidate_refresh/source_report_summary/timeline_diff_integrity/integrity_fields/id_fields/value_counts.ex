defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IdFields.ValueCounts do
  @moduledoc false

  alias __MODULE__.Values

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def id_counts(report, fields) do
    report_values = Values.report_values(report, fields)
    row_values = Values.row_values(report, fields)

    values_with_row_fallback(row_values, report_values)
    |> count_source_report_values()
  end

  def row_unique_counts(report, fields) do
    report_values = Values.unique_report_values(report, fields)
    row_values = Values.unique_row_values(report, fields)

    values_with_row_fallback(row_values, report_values)
    |> count_source_report_values()
  end

  defp values_with_row_fallback(row_values, report_values) do
    case row_values do
      [] -> report_values
      values -> values
    end
  end
end
