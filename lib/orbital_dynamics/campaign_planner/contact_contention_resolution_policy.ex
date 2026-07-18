defmodule OrbitalDynamics.CampaignPlanner.ContactContentionResolutionPolicy do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def build(owner) do
    policy =
      owner
      |> ValueEncoding.get_key("contact_contention_resolution_policy")
      |> case do
        %{} = policy -> ValueEncoding.stringify_keys(policy)
        _policy -> %{}
      end

    Map.merge(
      %{
        "selection_rule" => Map.get(policy, "selection_rule", "highest_score_earliest_start"),
        "tie_breakers" => Map.get(policy, "tie_breakers", ["starts_at_s", "id"]),
        "action" => Map.get(policy, "action", "recommend_preferred_contact_for_operator_review")
      },
      policy
    )
  end
end
