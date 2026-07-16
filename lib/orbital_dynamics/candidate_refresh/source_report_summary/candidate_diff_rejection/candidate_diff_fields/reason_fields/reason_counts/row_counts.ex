defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.ReasonFields.ReasonCounts.RowCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  alias __MODULE__.ListValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1
    ]

  def scalar(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> NormalizedToken.value()))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def list(rows, field) do
    rows
    |> ListValues.values(field)
    |> count_source_report_values()
  end

  def merge(reports, rows_fun, extractor) do
    reports
    |> Enum.map(fn report -> report |> rows_fun.() |> extractor.() end)
    |> merge_count_maps()
  end
end
