defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.GapCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows

  def downlink_gap_count(report) do
    report
    |> rows()
    |> Enum.count(&Rows.downlink_gap?/1)
  end

  def resource_margin_count(report) do
    report
    |> rows()
    |> Enum.count(&Rows.resource_margin_gap?/1)
  end

  defp rows(report), do: Rows.rows(report)
end
