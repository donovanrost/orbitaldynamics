defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonRowFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch
  alias OrbitalDynamics.CampaignPlanner.RecommendationObjective

  def target_branch_fields(%PlanBranch{provenance: provenance}) do
    metadata = get_in(provenance, ["branch_metadata"]) || %{}

    %{
      "target_branch_base_id" => Map.get(metadata, "target_branch_base_id"),
      "target_branch_identity" => Map.get(metadata, "target_branch_identity")
    }
    |> compact_map()
  end

  def feedback_fields(nil), do: %{}

  def feedback_fields(feedback_adjustments) do
    %{
      "feedback_score_adjustment" => Map.get(feedback_adjustments, "score_adjustment"),
      "contact_success_factor" => Map.get(feedback_adjustments, "contact_success_factor"),
      "contact_success_factor_source" =>
        Map.get(feedback_adjustments, "contact_success_factor_source"),
      "contact_success_factor_activity_source" =>
        Map.get(feedback_adjustments, "contact_success_factor_activity_source"),
      "observation_success_factor" => Map.get(feedback_adjustments, "observation_success_factor"),
      "observation_success_factor_source" =>
        Map.get(feedback_adjustments, "observation_success_factor_source"),
      "observation_success_factor_activity_source" =>
        Map.get(feedback_adjustments, "observation_success_factor_activity_source"),
      "image_quality_score" => Map.get(feedback_adjustments, "image_quality_score"),
      "image_quality_score_source" => Map.get(feedback_adjustments, "image_quality_score_source"),
      "image_quality_statuses" => Map.get(feedback_adjustments, "image_quality_statuses"),
      "image_quality_sources" => Map.get(feedback_adjustments, "image_quality_sources"),
      "cloud_cover_fraction" => Map.get(feedback_adjustments, "cloud_cover_fraction"),
      "cloud_cover_fraction_source" =>
        Map.get(feedback_adjustments, "cloud_cover_fraction_source"),
      "blur_score" => Map.get(feedback_adjustments, "blur_score"),
      "blur_score_source" => Map.get(feedback_adjustments, "blur_score_source"),
      "maneuver_success_factor" => Map.get(feedback_adjustments, "maneuver_success_factor"),
      "maneuver_success_factor_source" =>
        Map.get(feedback_adjustments, "maneuver_success_factor_source"),
      "command_success_factor" => Map.get(feedback_adjustments, "command_success_factor"),
      "command_success_factor_source" =>
        Map.get(feedback_adjustments, "command_success_factor_source"),
      "station_throughput_factor" => Map.get(feedback_adjustments, "station_throughput_factor"),
      "station_throughput_factor_source" =>
        Map.get(feedback_adjustments, "station_throughput_factor_source"),
      "station_throughput_factor_activity_source" =>
        Map.get(feedback_adjustments, "station_throughput_factor_activity_source"),
      "feedback_weight_sources" => Map.get(feedback_adjustments, "feedback_weight_sources"),
      "feedback_risk_types" =>
        feedback_adjustments
        |> Map.get("risk_indicators", [])
        |> Enum.map(&Map.get(&1, "type"))
        |> Enum.reject(&is_nil/1)
    }
    |> compact_map()
  end

  def objective_fields(objective_satisfaction) do
    RecommendationObjective.comparison_fields(objective_satisfaction)
  end

  def resource_fields(nil), do: %{}

  def resource_fields(resource_impacts) do
    resource_impacts = stringify_keys(resource_impacts)

    if map_size(resource_impacts) == 0 do
      %{}
    else
      resource_risk_types =
        resource_impacts
        |> Map.get("risk_indicators", [])
        |> Enum.map(&Map.get(&1, "type"))
        |> Enum.reject(&is_nil/1)
        |> Enum.sort()

      %{
        "fuel_margin" => Map.get(resource_impacts, "fuel_margin"),
        "power_margin" => Map.get(resource_impacts, "power_margin"),
        "storage_margin" => Map.get(resource_impacts, "storage_margin"),
        "downlink_capacity_margin" => Map.get(resource_impacts, "downlink_capacity_margin"),
        "thermal_margin_c" => Map.get(resource_impacts, "thermal_margin_c"),
        "spacecraft_availability" => Map.get(resource_impacts, "spacecraft_availability"),
        "payload_availability" => Map.get(resource_impacts, "payload_availability"),
        "antenna_availability" => Map.get(resource_impacts, "antenna_availability"),
        "resource_score_adjustment" => Map.get(resource_impacts, "score_adjustment"),
        "fuel_preservation_mode" => Map.get(resource_impacts, "fuel_preservation_mode"),
        "resource_risk_types" => resource_risk_types
      }
      |> compact_map()
    end
  end

  def repair_fields(repair_result) do
    repair_result = stringify_keys(repair_result)
    score_terms = Map.get(repair_result, "score_terms", %{})
    score_term_report = Map.get(repair_result, "score_term_report", %{})
    link_capacity_report = Map.get(repair_result, "link_capacity_report", %{})
    constraint_report = Map.get(repair_result, "constraint_report", %{})

    %{
      "repair_score" => Map.get(repair_result, "score"),
      "repair_score_term_count" => Map.get(score_term_report, "row_count"),
      "repair_score_term_keys" => Map.get(score_term_report, "score_term_keys"),
      "repair_activity_score" => Map.get(score_terms, "activity_score"),
      "repair_schedule_churn_penalty" => Map.get(score_terms, "schedule_churn_penalty"),
      "repair_schedule_move_penalty" => Map.get(score_terms, "schedule_move_penalty"),
      "repair_link_contact_count" => Map.get(link_capacity_report, "contact_count"),
      "repair_link_selected_contact_count" =>
        Map.get(link_capacity_report, "selected_contact_count"),
      "repair_link_selected_estimated_throughput_mb" =>
        Map.get(link_capacity_report, "selected_estimated_throughput_mb"),
      "repair_link_selected_capacity_adjusted_throughput_mb" =>
        Map.get(link_capacity_report, "selected_capacity_adjusted_throughput_mb"),
      "repair_link_required_downlink_mb" => Map.get(link_capacity_report, "required_downlink_mb"),
      "repair_link_selected_downlink_shortfall_mb" =>
        Map.get(link_capacity_report, "selected_downlink_shortfall_mb"),
      "repair_link_downlink_requirement_status" =>
        Map.get(link_capacity_report, "downlink_requirement_status"),
      "repair_link_actual_throughput_mb" => Map.get(link_capacity_report, "actual_throughput_mb"),
      "repair_link_actual_downlink_completion_ratio" =>
        Map.get(link_capacity_report, "actual_downlink_completion_ratio"),
      "repair_link_actual_downlink_shortfall_mb" =>
        Map.get(link_capacity_report, "actual_downlink_shortfall_mb"),
      "repair_link_actual_downlink_requirement_status" =>
        Map.get(link_capacity_report, "actual_downlink_requirement_status"),
      "repair_constraint_count" => Map.get(constraint_report, "constraint_count"),
      "repair_constraint_row_count" => Map.get(constraint_report, "row_count"),
      "repair_constraint_status" => Map.get(constraint_report, "status"),
      "repair_constraint_pass_count" => constraint_status_count(constraint_report, "pass"),
      "repair_constraint_warning_count" => constraint_status_count(constraint_report, "warning"),
      "repair_constraint_fail_count" => constraint_status_count(constraint_report, "fail"),
      "repair_constraint_failed_ids" => constraint_ids_for_status(constraint_report, "fail"),
      "repair_constraint_warning_ids" => constraint_ids_for_status(constraint_report, "warning")
    }
    |> compact_map()
  end

  defp constraint_status_count(report, status) do
    report
    |> Map.get("rows", [])
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  defp constraint_ids_for_status(report, status) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&(Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "constraint_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
