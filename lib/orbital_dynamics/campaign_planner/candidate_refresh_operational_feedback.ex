defmodule OrbitalDynamics.CampaignPlanner.CandidateRefreshOperationalFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackNormalization,
    ScalarValues,
    ValueEncoding
  }

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def feedback(%{} = candidate_refresh) do
    candidate_refresh
    |> Map.get("operational_feedback", %{})
    |> OperationalFeedbackNormalization.normalize(operational_feedback_normalization_callbacks())
  end

  def feedback(_candidate_refresh) do
    OperationalFeedbackNormalization.normalize(
      %{},
      operational_feedback_normalization_callbacks()
    )
  end

  def metadata(%{} = candidate_refresh) do
    %{
      "source_report_contract" => "candidate_refresh.v1",
      "source_report_count" => 1,
      "source_refresh_id" => Map.get(candidate_refresh, "refresh_id"),
      "source_snapshot_id" => Map.get(candidate_refresh, "snapshot_id"),
      "source_candidate_count" => length(Map.get(candidate_refresh, "candidate_activities", [])),
      "source_invalidated_candidate_count" =>
        length(Map.get(candidate_refresh, "invalidated_candidates", [])),
      "source_operational_feedback_provenance" =>
        get_in(candidate_refresh, ["provenance", "operational_feedback"])
    }
    |> ValueEncoding.compact_map()
  end

  def metadata(_candidate_refresh), do: %{}

  defp operational_feedback_normalization_callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]
end
