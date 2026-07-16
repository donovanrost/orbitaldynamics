defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => source_contract(reports),
      "count" => length(sources),
      "row_count" => sum_report_count(reports, &ReportShape.source_row_count/1),
      "application_count" => sum_report_count(reports, &ReportShape.application_count/1),
      "trust_boundary_status" => ReportShape.trust_boundary_status(reports),
      "trust_boundaries" => ReportShape.trust_boundaries(reports)
    }
  end

  defp source_contract(reports) do
    reports
    |> Enum.map(fn report ->
      Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> case do
      [contract] -> contract
      [] -> nil
      _contracts -> "timeline_transition_application_report.v1"
    end
  end
end
