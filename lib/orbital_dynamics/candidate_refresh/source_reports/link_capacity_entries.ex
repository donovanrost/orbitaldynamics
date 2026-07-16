defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacitySummaryReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      entry_from_report(entry_path, stringify_keys(entry_value))
    end)
  end

  def entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, stringify_keys(entry_value))
    end)
  end

  def report?(%{} = report) do
    rows = Map.get(report, "rows") || Map.get(report, :rows)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    source_summary_schema_contract =
      Map.get(report, "source_summary_schema_contract") ||
        Map.get(report, :source_summary_schema_contract)

    (is_list(rows) and schema_contract in [nil, "link_capacity_report.v1"]) or
      source_summary_schema_contract in ["link_capacity_summary.v1", "relay_data_path_summary.v1"]
  end

  def report?(_report), do: false

  defp entry_from_report(entry_path, report) do
    cond do
      LinkCapacitySummaryReports.link_capacity_summary?(report) ->
        {entry_path, LinkCapacitySummaryReports.report_from_summary(report)}

      LinkCapacitySummaryReports.relay_data_path_summary?(report) ->
        {entry_path, LinkCapacitySummaryReports.report_from_summary(report)}

      report?(report) ->
        {entry_path, report}

      true ->
        nil
    end
  end

  defp stringify_keys(value), do: LinkCapacityReviewRows.stringify_keys(value)
end
