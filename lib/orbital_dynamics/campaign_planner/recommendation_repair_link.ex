defmodule OrbitalDynamics.CampaignPlanner.RecommendationRepairLink do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{} = recommended) do
    link_capacity_report =
      recommended.repair_result
      |> Map.get("link_capacity_report", %{})
      |> stringify_keys()

    shortfall = Map.get(link_capacity_report, "selected_downlink_shortfall_mb")

    if positive_number?(shortfall) do
      required = Map.get(link_capacity_report, "required_downlink_mb")
      selected = Map.get(link_capacity_report, "selected_capacity_adjusted_throughput_mb")

      [
        %{
          "type" => "repair_link_capacity",
          "recommended_branch_id" => recommended.id,
          "required_downlink_mb" => required,
          "selected_capacity_adjusted_throughput_mb" => selected,
          "selected_downlink_shortfall_mb" => shortfall,
          "downlink_requirement_status" =>
            Map.get(link_capacity_report, "downlink_requirement_status"),
          "selected_contact_count" => Map.get(link_capacity_report, "selected_contact_count"),
          "selected_contact_ids" => Map.get(link_capacity_report, "selected_contact_ids"),
          "reason" =>
            "selected repaired downlink capacity #{selected} MB below required #{required} MB by #{shortfall} MB"
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  def rows(_branch), do: []

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
