defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.{RowCounts, RowFields}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{}
    |> Map.merge(numeric_count_fields(reports))
    |> Map.merge(RowFields.fields(reports))
  end

  def row_count(reports), do: sum_report_count(reports, &RowCounts.row_count(&1, "row_count"))

  defp numeric_count_fields(reports) do
    Map.new(FieldSpecs.numeric_count_fields(), fn field ->
      {field, sum_report_count(reports, &numeric_report_count(&1, field))}
    end)
  end
end
