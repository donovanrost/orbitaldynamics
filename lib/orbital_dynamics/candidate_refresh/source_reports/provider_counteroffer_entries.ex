defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      entry_from_report(entry_path, ProviderCounterofferEncoding.stringify_keys(entry_value))
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, ProviderCounterofferEncoding.stringify_keys(entry_value))
    end)
  end

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    rows = Map.get(report, "rows") || Map.get(report, :rows)

    is_list(rows) and schema_contract in [nil, "provider_counteroffer_report.v1"]
  end

  def report?(_report), do: false

  defp entry_from_report(entry_path, report) do
    cond do
      report?(report) ->
        {entry_path, report}

      ProviderCounterofferSummaryReports.review_summary?(report) ->
        {entry_path, ProviderCounterofferSummaryReports.report_from_review_summary(report)}

      ProviderCounterofferSummaryReports.import_readiness_summary?(report) ->
        {entry_path,
         ProviderCounterofferSummaryReports.report_from_import_readiness_summary(report)}

      ProviderCounterofferSummaryReports.plan_impact_summary?(report) ->
        {entry_path, ProviderCounterofferSummaryReports.report_from_plan_impact_summary(report)}

      true ->
        nil
    end
  end
end
