defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntent do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentEntryEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentReviewRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentSourcePredicate
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      source = stringify_keys(entry_value)

      if source?(source) do
        {entry_path, source}
      end
    end)
  end

  def build_entries(path, value, builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      source = stringify_keys(entry_value)

      builder.(entry_path, source)
      |> Enum.map(&ContactIntentEntryEncoding.inherit_result_artifact_trust_boundary(&1, source))
      |> Enum.with_index()
      |> Enum.map(fn {intent, index} ->
        {"#{entry_path}.rows.source_contact_intent[#{index}]", intent}
      end)
    end)
  end

  def operator_review_package_intents(_path, %{} = package) do
    ContactIntentReviewRows.operator_review_package_intents(package)
  end

  def cadence_import_manifest_intents(_path, %{} = manifest) do
    ContactIntentReviewRows.cadence_import_manifest_intents(manifest)
  end

  def source?(source), do: ContactIntentSourcePredicate.source?(source)

  defp stringify_keys(value), do: ContactIntentEntryEncoding.stringify_keys(value)
end
