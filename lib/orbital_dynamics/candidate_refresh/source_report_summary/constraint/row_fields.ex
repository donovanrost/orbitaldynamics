defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    row_count_fields(reports)
    |> Map.merge(CountMaps.fields(reports))
  end

  def row_trust_boundaries(rows, report), do: RowValues.row_trust_boundaries(rows, report)

  defp row_count_fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &RowValues.row_count/1),
      "downlink_gap_row_count" => sum_report_count(reports, &RowValues.downlink_gap_count/1),
      "resource_margin_row_count" => sum_report_count(reports, &RowValues.resource_margin_count/1)
    }
  end
end
