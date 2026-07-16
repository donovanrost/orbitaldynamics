defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReportClassification
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewRows
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = stringify_keys(entry_value)

      cond do
        ResourceFilterReportClassification.summary?(report) ->
          {entry_path, SourceReportSummary.ResourceFilter.report_from_summary(report)}

        ResourceFilterReportClassification.report?(report) ->
          {entry_path, report}

        true ->
          nil
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, stringify_keys(entry_value))
    end)
  end

  defp stringify_keys(value), do: ResourceFilterReviewRows.stringify_keys(value)
end
