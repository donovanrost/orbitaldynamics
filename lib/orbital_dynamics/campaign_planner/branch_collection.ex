defmodule OrbitalDynamics.CampaignPlanner.BranchCollection do
  @moduledoc false

  def baseline do
    %{
      "id" => "baseline",
      "label" => "Mission-state baseline",
      "metadata" => %{"derived_source" => "branch_generation.baseline"}
    }
  end

  def dedupe(branches) do
    branches
    |> Enum.reduce({MapSet.new(), []}, fn branch, {seen, kept} ->
      if MapSet.member?(seen, branch["id"]) do
        {seen, kept}
      else
        {MapSet.put(seen, branch["id"]), [branch | kept]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  def dedupe_contact_intent_pressure(branches) do
    branches
    |> Enum.reduce({MapSet.new(), []}, fn branch, {seen, kept} ->
      identity = contact_intent_pressure_identity(branch)

      cond do
        is_nil(identity) ->
          {seen, [branch | kept]}

        MapSet.member?(seen, identity) ->
          {seen, kept}

        true ->
          {MapSet.put(seen, identity), [branch | kept]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp contact_intent_pressure_identity(%{"events" => [event | _events]}) do
    if event["feedback_scope"] == "contact_intent" do
      contact_id =
        event["source_activity_id"] ||
          event["contact_id"] ||
          event["source_activity_ids"] |> List.wrap() |> List.first()

      gate_status = event["contact_intent_gate_status"]

      if contact_id in [nil, ""] or gate_status in [nil, ""] do
        nil
      else
        {gate_status, contact_id}
      end
    end
  end

  defp contact_intent_pressure_identity(_branch), do: nil
end
