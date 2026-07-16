defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.SourceReport.ReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.SourceReport.ReportCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(report) do
    trust_boundaries = RowFields.trust_boundaries(report)

    %{
      "source" => "operational_timeline_report.rows",
      "source_report_contract" =>
        Map.get(report, "schema_contract", "operational_timeline_report.v1"),
      "source_report_count" => 1,
      "input_keys" => RowFields.input_keys([report]),
      "trust_boundary_status" => trust_boundary_status(trust_boundaries),
      "trust_boundaries" => trust_boundaries
    }
    |> Map.merge(ReportCounts.fields(report))
    |> compact_map()
  end

  defp trust_boundary_status([]), do: "missing"
  defp trust_boundary_status(_trust_boundaries), do: "declared"
end
