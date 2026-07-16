defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferDirectReportSources do
  @moduledoc false

  @provider_counteroffer_report_fields [
    "source_provider_counteroffer_report",
    "provider_counteroffer_report",
    "source_provider_counteroffer_review_summary",
    "provider_counteroffer_review_summary",
    "source_provider_counteroffer_import_readiness_summary",
    "provider_counteroffer_import_readiness_summary",
    "source_provider_counteroffer_plan_impact_summary",
    "provider_counteroffer_plan_impact_summary"
  ]

  def sources(refresh) do
    scoped_sources(refresh, "accepted_planning_state") ++
      scoped_sources(refresh, "mission_state") ++ root_sources(refresh)
  end

  defp scoped_sources(refresh, scope) do
    Enum.map(@provider_counteroffer_report_fields, fn field ->
      {"#{scope}.#{field}", get_in(refresh, [scope, field])}
    end)
  end

  defp root_sources(refresh) do
    Enum.map(@provider_counteroffer_report_fields, fn field ->
      {field, Map.get(refresh, field)}
    end)
  end
end
