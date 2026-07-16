defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [normalize_trust_boundaries: 1]

  def trust_boundaries(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  def trust_boundaries(%{"rows" => rows} = report) when is_list(rows) do
    RowValues.with_rows(report, rows)
  end

  def trust_boundaries(%{} = report) do
    RowValues.without_rows(report)
  end

  def trust_boundaries(_report), do: []
end
