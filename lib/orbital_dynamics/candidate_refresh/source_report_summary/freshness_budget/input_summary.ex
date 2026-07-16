defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.{
    FreshnessFields,
    RefreshBudgetFields,
    SourceFields
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def freshness_report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports, "freshness_report.v1")
    |> Map.merge(FreshnessFields.fields(reports))
    |> compact_map()
  end

  def refresh_budget_report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    SourceFields.fields(sources, reports, "refresh_budget_report.v1")
    |> Map.merge(RefreshBudgetFields.fields(reports))
    |> compact_map()
  end
end
