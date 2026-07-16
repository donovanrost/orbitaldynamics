defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReportClassification do
  @moduledoc false

  def report?(%{} = report) do
    rows = Map.get(report, "suppressed_candidates") || Map.get(report, :suppressed_candidates)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    source_summary_schema_contract =
      Map.get(report, "source_summary_schema_contract") ||
        Map.get(report, :source_summary_schema_contract)

    (is_list(rows) and schema_contract in [nil, "resource_filter_report.v1"]) or
      source_summary_schema_contract == "resource_filter_summary.v1"
  end

  def report?(_report), do: false

  def summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    review_rows = Map.get(summary, "review_rows") || Map.get(summary, :review_rows)

    is_list(review_rows) and
      (model == "artifact_only_resource_filter_summary" or
         schema_contract == "resource_filter_summary.v1")
  end

  def summary?(_summary), do: false
end
