defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.SourceFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      source_report_trust_boundaries: 1
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "contact_contention_report.v1",
      "count" => length(sources),
      "trust_boundary_status" => trust_boundary_status(reports),
      "trust_boundaries" => trust_boundaries(reports)
    }
  end

  defp trust_boundary_status(reports) do
    case trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp trust_boundaries(reports) do
    reports
    |> source_report_trust_boundaries()
    |> Kernel.++(
      reports
      |> Enum.flat_map(fn report ->
        (Map.get(report, "conflict_groups", []) ++ Map.get(report, "invalid_contact_inputs", []))
        |> source_report_trust_boundaries()
      end)
    )
    |> Enum.uniq()
    |> Enum.sort()
  end
end
