defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.Applications.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_report(report) do
    report
    |> Map.get("applications", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def count(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> non_empty_counts()
  end

  defp non_empty_counts(counts) when counts == %{}, do: nil
  defp non_empty_counts(counts), do: counts
end
