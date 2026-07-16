defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ReportNormalizer do
  @moduledoc false

  alias __MODULE__.SummaryReports
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def normalize(%{} = summary) do
    summary = EncodedValue.stringify_keys(summary)
    rows = normalized_rows(summary)

    SummaryReports.normalize(summary, rows)
  end

  def normalize(report), do: report

  defp normalized_rows(summary) do
    summary
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
