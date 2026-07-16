defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.Values

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [normalize_trust_boundaries: 1]

  def status(reports) do
    case values(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def values(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&Values.for_report/1)
    |> normalize_trust_boundaries()
  end
end
