defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReportRecognition do
  @moduledoc false

  def report?(%{} = report) do
    rows = Map.get(report, "rows") || Map.get(report, :rows)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    source_summary_schema_contract =
      Map.get(report, "source_summary_schema_contract") ||
        Map.get(report, :source_summary_schema_contract)

    is_list(rows) and
      (schema_contract in [nil, "timeline_diff_report.v1", "timeline_diff_summary.v1"] or
         source_summary_schema_contract == "timeline_diff_summary.v1")
  end

  def report?(_report), do: false
end
