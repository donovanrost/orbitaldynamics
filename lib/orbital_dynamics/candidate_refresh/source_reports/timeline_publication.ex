defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublication do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      summary = stringify_keys(entry_value)

      if summary?(summary) do
        {entry_path, summary}
      end
    end)
  end

  def operator_review_entries(path, value) do
    TimelinePublicationHandoffReports.operator_review_entries(path, value)
  end

  def cadence_import_entries(path, value) do
    TimelinePublicationHandoffReports.cadence_import_entries(path, value)
  end

  def summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    publication_id = Map.get(summary, "publication_id") || Map.get(summary, :publication_id)

    source_artifact_id =
      Map.get(summary, "source_artifact_id") || Map.get(summary, :source_artifact_id)

    is_binary(publication_id) and is_binary(source_artifact_id) and
      (model == "artifact_only_timeline_publication_summary" or
         schema_contract == "timeline_publication_summary.v1")
  end

  def summary?(_summary), do: false

  defp stringify_keys(value), do: TimelinePublicationEncoding.stringify_keys(value)
end
