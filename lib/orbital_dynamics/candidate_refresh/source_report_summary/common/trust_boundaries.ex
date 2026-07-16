defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.NormalizedValues

  def source_report_status(reports) do
    case source_report_values(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def source_report_values(reports) do
    reports
    |> Enum.flat_map(fn report ->
      [
        Map.get(report, "trust_boundary"),
        get_in(report, ["provenance", "trust_boundary"]),
        get_in(report, ["metadata", "trust_boundary"])
        | List.wrap(Map.get(report, "trust_boundaries"))
      ]
    end)
    |> normalize()
  end

  def normalize(values) do
    NormalizedValues.from(values)
  end
end
