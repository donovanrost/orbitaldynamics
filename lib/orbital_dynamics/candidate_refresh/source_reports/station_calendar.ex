defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendar do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRows

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = StationCalendarValues.stringify_keys(entry_value)

      cond do
        StationCalendarValues.precedence_summary?(report) ->
          {entry_path, StationCalendarValues.report_from_precedence_summary(report)}

        report?(report) ->
          {entry_path, report}

        true ->
          nil
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      builder.(entry_path, StationCalendarValues.stringify_keys(entry_value))
    end)
  end

  def operator_review_package_report(path, %{} = package) do
    StationCalendarReviewRows.operator_review_package_report(path, package)
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    StationCalendarReviewRows.cadence_import_manifest_report(path, manifest)
  end

  def report?(report), do: StationCalendarValues.report?(report)
end
