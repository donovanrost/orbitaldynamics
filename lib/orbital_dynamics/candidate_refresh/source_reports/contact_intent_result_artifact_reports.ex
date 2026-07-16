defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntent
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentResultArtifactEncoding

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = ContactIntentResultArtifactEncoding.stringify_keys(artifact)

      [
        {"#{path}.source_contact_intent", Map.get(artifact, "source_contact_intent")},
        {"#{path}.source_contact_intents", Map.get(artifact, "source_contact_intents")},
        {"#{path}.source_contact_intent_summary",
         Map.get(artifact, "source_contact_intent_summary")},
        {"#{path}.contact_intent_summary", Map.get(artifact, "contact_intent_summary")},
        {"#{path}.contact_intent", Map.get(artifact, "contact_intent")},
        {"#{path}.contact_intents", Map.get(artifact, "contact_intents")}
      ]
      |> Enum.flat_map(fn {entry_path, intent_or_intents} ->
        ContactIntent.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(intent_or_intents, artifact)
        )
      end)
    end)
  end
end
