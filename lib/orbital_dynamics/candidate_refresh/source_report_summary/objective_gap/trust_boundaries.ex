defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.ReportBoundaries

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1
    ]

  def status(family, reports) do
    case values(family, reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def values(:objective_satisfaction, reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&ReportBoundaries.objective_satisfaction/1)
    |> normalize_trust_boundaries()
  end

  def values(:objective_tradeoff, reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&ReportBoundaries.objective_tradeoff/1)
    |> normalize_trust_boundaries()
  end

  def values(:score_term, reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&ReportBoundaries.score_term/1)
    |> normalize_trust_boundaries()
  end
end
