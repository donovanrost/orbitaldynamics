defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.ApplicationRows

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

  def values(reports) do
    reports
    |> Enum.flat_map(&report_boundaries/1)
    |> normalize_trust_boundaries()
  end

  defp report_boundaries(%{"applications" => applications} = report)
       when is_list(applications) do
    applications
    |> ApplicationRows.trust_boundaries()
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  defp report_boundaries(%{} = report) do
    source_report_trust_boundaries([report])
  end
end
