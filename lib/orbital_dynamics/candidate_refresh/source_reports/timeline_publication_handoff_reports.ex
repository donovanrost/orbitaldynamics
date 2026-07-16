defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffRows

  def operator_review_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      operator_review_package_summary(
        entry_path,
        TimelinePublicationHandoffRows.stringify_keys(entry_value)
      )
    end)
  end

  def cadence_import_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      cadence_import_manifest_summary(
        entry_path,
        TimelinePublicationHandoffRows.stringify_keys(entry_value)
      )
    end)
  end

  defp operator_review_package_summary(path, %{} = package) do
    TimelinePublicationHandoffRows.summary_from_handoff_rows(
      "#{path}.rows.source_timeline_publication_summary",
      package,
      "timeline_publication_review"
    )
  end

  defp cadence_import_manifest_summary(path, %{} = manifest) do
    TimelinePublicationHandoffRows.summary_from_handoff_rows(
      "#{path}.rows.source_timeline_publication_summary",
      manifest,
      "review_timeline_publication"
    )
  end
end
