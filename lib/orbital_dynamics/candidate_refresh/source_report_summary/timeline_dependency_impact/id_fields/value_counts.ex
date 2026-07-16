defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.IdFields.ValueCounts do
  @moduledoc false

  alias __MODULE__.Values

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def count(report, fields) do
    report_values = Values.report_values(report, fields)
    row_values = Values.row_values(report, fields)

    if(row_values == [], do: report_values, else: row_values)
    |> count_source_report_values()
  end

  def row_unique_count(report, fields) do
    report_values = Values.unique_report_values(report, fields)
    row_values = Values.unique_row_values(report, fields)

    if(row_values == [], do: report_values, else: row_values)
    |> count_source_report_values()
  end
end
