defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimeline do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReviewImportReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineValues

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = OperationalTimelineValues.stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def operator_review_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      OperationalTimelineReviewImportReports.operator_review_package_report(
        entry_path,
        OperationalTimelineValues.stringify_keys(entry_value)
      )
    end)
  end

  def cadence_import_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      OperationalTimelineReviewImportReports.cadence_import_manifest_report(
        entry_path,
        OperationalTimelineValues.stringify_keys(entry_value)
      )
    end)
  end

  def report?(report), do: OperationalTimelineValues.report?(report)
end
