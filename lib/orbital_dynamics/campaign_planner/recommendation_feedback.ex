defmodule OrbitalDynamics.CampaignPlanner.RecommendationFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{id: branch_id, feedback_adjustments: adjustments})
      when is_map(adjustments) do
    if feedback_adjustment_row?(adjustments) do
      [
        %{
          "type" => "operational_feedback_driver",
          "recommended_branch_id" => branch_id,
          "feedback_score_adjustment" => Map.get(adjustments, "score_adjustment"),
          "contact_success_factor" => Map.get(adjustments, "contact_success_factor"),
          "contact_success_factor_source" =>
            Map.get(adjustments, "contact_success_factor_source"),
          "contact_success_factor_activity_source" =>
            Map.get(adjustments, "contact_success_factor_activity_source"),
          "observation_success_factor" => Map.get(adjustments, "observation_success_factor"),
          "observation_success_factor_source" =>
            Map.get(adjustments, "observation_success_factor_source"),
          "observation_success_factor_activity_source" =>
            Map.get(adjustments, "observation_success_factor_activity_source"),
          "image_quality_score" => Map.get(adjustments, "image_quality_score"),
          "image_quality_score_source" => Map.get(adjustments, "image_quality_score_source"),
          "image_quality_statuses" => Map.get(adjustments, "image_quality_statuses"),
          "image_quality_sources" => Map.get(adjustments, "image_quality_sources"),
          "cloud_cover_fraction" => Map.get(adjustments, "cloud_cover_fraction"),
          "cloud_cover_fraction_source" => Map.get(adjustments, "cloud_cover_fraction_source"),
          "blur_score" => Map.get(adjustments, "blur_score"),
          "blur_score_source" => Map.get(adjustments, "blur_score_source"),
          "maneuver_success_factor" => Map.get(adjustments, "maneuver_success_factor"),
          "maneuver_success_factor_source" =>
            Map.get(adjustments, "maneuver_success_factor_source"),
          "command_success_factor" => Map.get(adjustments, "command_success_factor"),
          "command_success_factor_source" =>
            Map.get(adjustments, "command_success_factor_source"),
          "station_throughput_factor" => Map.get(adjustments, "station_throughput_factor"),
          "station_throughput_factor_source" =>
            Map.get(adjustments, "station_throughput_factor_source"),
          "station_throughput_factor_activity_source" =>
            Map.get(adjustments, "station_throughput_factor_activity_source"),
          "feedback_weight_sources" => Map.get(adjustments, "feedback_weight_sources"),
          "feedback_risk_types" =>
            adjustments
            |> Map.get("risk_indicators", [])
            |> Enum.map(&Map.get(&1, "type"))
            |> Enum.reject(&is_nil/1),
          "reason" => "recommended branch score includes operational feedback adjustments"
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  def rows(_branch), do: []

  defp feedback_adjustment_row?(adjustments) do
    Enum.any?(
      [
        "contact_success_factor",
        "observation_success_factor",
        "maneuver_success_factor",
        "command_success_factor",
        "station_throughput_factor"
      ],
      &is_number(Map.get(adjustments, &1))
    )
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
