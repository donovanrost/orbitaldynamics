defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentEntryEncoding do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentEntryValueEncoding

  def inherit_result_artifact_trust_boundary(value, artifact) do
    value = stringify_keys(value)

    case value do
      %{} = value ->
        trust_boundary = result_artifact_trust_boundary(artifact)

        if trust_boundary in [nil, ""] or
             OperationalFeedback.source_timeline_feedback_trust_boundaries(value) != [] do
          value
        else
          Map.update(
            value,
            "provenance",
            %{"trust_boundary" => ContactIntentEntryValueEncoding.encode_value(trust_boundary)},
            fn
              %{} = provenance ->
                Map.put_new(
                  provenance,
                  "trust_boundary",
                  ContactIntentEntryValueEncoding.encode_value(trust_boundary)
                )

              _provenance ->
                %{
                  "trust_boundary" => ContactIntentEntryValueEncoding.encode_value(trust_boundary)
                }
            end
          )
        end

      value ->
        value
    end
  end

  def stringify_keys(value), do: ContactIntentEntryValueEncoding.stringify_keys(value)

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
