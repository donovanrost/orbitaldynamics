defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessSummaryReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryRecognition

  defdelegate review_summary?(summary), to: ProviderCounterofferSummaryRecognition

  def import_readiness_summary?(summary),
    do: ProviderCounterofferImportReadinessSummaryReports.import_readiness_summary?(summary)

  defdelegate plan_impact_summary?(summary), to: ProviderCounterofferSummaryRecognition

  def report_from_review_summary(%{} = summary) do
    summary
    |> ProviderCounterofferSummaryReportFields.review_fields()
    |> maybe_put("provenance", Map.get(summary, "provenance"))
    |> compact_map()
  end

  def report_from_plan_impact_summary(%{} = summary) do
    summary
    |> ProviderCounterofferSummaryReportFields.plan_impact_fields()
    |> maybe_put("provenance", Map.get(summary, "provenance"))
    |> compact_map()
  end

  def report_from_import_readiness_summary(%{} = summary) do
    ProviderCounterofferImportReadinessSummaryReports.report_from_import_readiness_summary(
      summary
    )
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
