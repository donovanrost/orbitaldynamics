defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.SourceFields.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1,
      source_report_trust_boundaries: 1
    ]

  def status(reports) do
    case values(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  def values(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&source_trust_boundaries/1)
    |> normalize_trust_boundaries()
  end

  defp source_trust_boundaries(%{} = report) do
    RowValues.values(report) ++ source_report_trust_boundaries([report])
  end
end
