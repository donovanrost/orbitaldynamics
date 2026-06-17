defmodule OrbitalDynamics.CampaignPlanner.RecommendationPlanChange do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CandidateDiffMetadata
  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{} = recommended) do
    delta_rows(recommended) ++ addition_rows(recommended)
  end

  def rows(_branch), do: []

  defp delta_rows(%PlanBranch{} = recommended) do
    recommended.repair_result
    |> Map.get("deltas", [])
    |> Enum.reject(&(&1["repair_action"] == "preserved"))
    |> Enum.map(fn delta ->
      %{
        "type" => "plan_delta",
        "activity_id" => delta["activity_id"],
        "activity_type" => delta["activity_type"],
        "action" => delta["repair_action"],
        "reason" => delta["reason"]
      }
    end)
  end

  defp addition_rows(%PlanBranch{} = recommended) do
    recommended.candidate_plan
    |> Map.get("strategic_additions", [])
    |> Enum.map(fn activity ->
      %{
        "type" => "strategic_addition",
        "activity_id" => activity_id(activity),
        "target_id" => activity["target_id"],
        "reason" => get_in(activity, ["repair", "reason"]),
        "feasibility_status" => get_in(activity, ["feasibility", "status"]),
        "feedback_source" => get_in(activity, ["feasibility", "feedback_source"]),
        "feedback_scope" => get_in(activity, ["feasibility", "feedback_scope"]),
        "trust_boundary" => get_in(activity, ["feasibility", "trust_boundary"]),
        "source_event_type" => get_in(activity, ["feasibility", "source_event_type"]),
        "source_event_id" => get_in(activity, ["feasibility", "source_event_id"]),
        "objective_id" => get_in(activity, ["feasibility", "objective_id"]),
        "objective_ids" => get_in(activity, ["feasibility", "objective_ids"]),
        "objective_type" => get_in(activity, ["feasibility", "objective_type"]),
        "target_ids" => get_in(activity, ["feasibility", "target_ids"]),
        "collection_id" => get_in(activity, ["feasibility", "collection_id"]),
        "collection_ids" => get_in(activity, ["feasibility", "collection_ids"]),
        "product_id" => get_in(activity, ["feasibility", "product_id"]),
        "product_ids" => get_in(activity, ["feasibility", "product_ids"]),
        "payload_id" => get_in(activity, ["feasibility", "payload_id"]),
        "payload_ids" => get_in(activity, ["feasibility", "payload_ids"]),
        "instrument_id" => get_in(activity, ["feasibility", "instrument_id"]),
        "instrument_ids" => get_in(activity, ["feasibility", "instrument_ids"]),
        "requires_approval" => get_in(activity, ["repair", "requires_approval"]) || false
      }
      |> compact_map()
      |> CandidateDiffMetadata.put(
        get_in(activity, ["repair", "candidate_diff"]) ||
          get_in(activity, ["feasibility", "candidate_diff"])
      )
    end)
  end

  defp activity_id(activity), do: encode_value(Map.fetch!(activity, "id"))

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
