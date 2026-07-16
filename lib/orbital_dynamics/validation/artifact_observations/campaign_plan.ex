defmodule OrbitalDynamics.Validation.ArtifactObservations.CampaignPlan do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_version" => Map.get(artifact, "schema_version"),
      "planner" => Map.get(artifact, "planner"),
      "activity_count" => count(artifact, "activities"),
      "proposed_contact_count" => count(artifact, "proposed_contacts"),
      "contact_intent_count" => count(artifact, "contact_intents"),
      "candidate_activity_count" => count(artifact, "candidate_activities"),
      "ranked_timeline_count" => count(artifact, "ranked_timelines"),
      "warning_count" => count(artifact, "warnings")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
