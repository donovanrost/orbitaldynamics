defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReportRecognition
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffResultArtifactEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffSummaryReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      entry_value = stringify_keys(entry_value)

      cond do
        TimelineDiffSummaryReports.summary?(entry_value) ->
          {entry_path, TimelineDiffSummaryReports.report_from_summary(entry_value)}

        report?(entry_value) ->
          {entry_path, entry_value}

        true ->
          nil
      end
    end)
  end

  def result_artifact_entries(path, artifact) do
    EntryFallbacks.map_entry(path, artifact, fn entry_path, entry_artifact ->
      TimelineDiffResultArtifactEntries.entries(entry_path, entry_artifact)
    end)
  end

  def operator_review_entries(path, value) do
    TimelineDiffReviewImportReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    TimelineDiffReviewImportReports.cadence_import_entries(path, value)
  end

  def row_from_review_or_import_row(%{} = row) do
    TimelineDiffReviewImportReports.row_from_review_or_import_row(row)
  end

  def row_from_review_or_import_row(_row), do: nil

  def report?(report), do: TimelineDiffReportRecognition.report?(report)

  defp stringify_keys(value), do: TimelineDiffEncoding.stringify_keys(value)
end
