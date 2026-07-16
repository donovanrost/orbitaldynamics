defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewFeedbackRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def operational_timeline_rows(rows), do: operational_timeline_rows(rows, callbacks())

  def operational_timeline_rows(rows, callbacks) do
    rows
    |> Enum.filter(&(&1["review_type"] == "operational_timeline_review"))
    |> Enum.map(&operational_timeline_row(&1, callbacks))
  end

  def realized_feedback_rows(rows), do: realized_feedback_rows(rows, callbacks())

  def realized_feedback_rows(rows, callbacks) do
    rows
    |> Enum.filter(&(&1["review_type"] == "realized_feedback"))
    |> Enum.map(&realized_feedback_row(&1, callbacks))
  end

  def realized_feedback_type(row, source) do
    row["activity_type"] || source["activity_type"] || source["planned_type"] ||
      source["realized_type"] ||
      feedback_kind_activity_type(row["feedback_kind"] || source["feedback_kind"])
  end

  def operational_timeline_row(row), do: operational_timeline_row(row, callbacks())

  def operational_timeline_row(row, callbacks) do
    row
    |> Map.get("source_operational_timeline", row)
    |> stringify_keys(callbacks)
    |> put_fallback(callbacks, row, "activity_id")
    |> put_fallback(callbacks, row, "id", "activity_id")
    |> put_fallback(callbacks, row, "type", "activity_type")
    |> put_fallback(callbacks, row, "activity_type")
    |> put_fallback(callbacks, row, "timeline_id")
    |> put_fallback(callbacks, row, "scenario_id")
    |> put_fallback(callbacks, row, "ground_station_id")
    |> put_fallback(callbacks, row, "station_id")
    |> put_fallback(callbacks, row, "target_id")
    |> put_fallback(callbacks, row, "status")
    |> put_operational_feedback_fallbacks(callbacks, row)
    |> put_operational_timeline_integrity_fallbacks(callbacks, row)
    |> put_feedback_weight_fallbacks(callbacks, row)
    |> put_if_present(
      callbacks,
      "_operator_review_invalid_activity_input",
      row["invalid_activity_input"]
    )
  end

  defp realized_feedback_row(row, callbacks) do
    source =
      row
      |> Map.get("source_feedback", row)
      |> stringify_keys(callbacks)

    feedback_status = row["feedback_status"] || source["status"]
    realized_status = row["realized_status"] || source["realized_status"] || row["status"]

    source
    |> put_if_present(callbacks, "feedback_status", feedback_status)
    |> put_if_present(callbacks, "status", realized_status)
    |> put_fallback(callbacks, row, "activity_id")
    |> put_fallback(callbacks, row, "id", "activity_id")
    |> put_fallback(callbacks, row, "timeline_id", "timeline_identity")
    |> put_fallback(callbacks, row, "scenario_id")
    |> put_fallback(callbacks, row, "ground_station_id")
    |> put_fallback(callbacks, row, "ground_station_id", "planned_ground_station_id")
    |> put_fallback(callbacks, row, "ground_station_id", "realized_ground_station_id")
    |> put_fallback(callbacks, row, "target_id")
    |> put_fallback(callbacks, row, "target_id", "planned_target_id")
    |> put_fallback(callbacks, row, "target_id", "realized_target_id")
    |> put_operational_feedback_fallbacks(callbacks, row)
    |> put_fallback(callbacks, row, "completed_fraction")
    |> put_feedback_weight_fallbacks(callbacks, row)
    |> put_if_present(callbacks, "type", realized_feedback_type(row, source))
    |> put_if_present(callbacks, "_operator_review_feedback_status", feedback_status)
    |> put_if_present(
      callbacks,
      "_operator_review_match_strategy",
      row["match_strategy"] || source["match_strategy"]
    )
    |> put_if_present(
      callbacks,
      "_operator_review_realized_match_count",
      row["realized_match_count"] || source["realized_match_count"]
    )
    |> put_if_present(
      callbacks,
      "_operator_review_invalid_realized_feedback_input",
      row["invalid_realized_feedback_input"] || source["invalid_realized_feedback_input"]
    )
    |> put_if_present(
      callbacks,
      "_operator_review_invalid_activity_input",
      row["invalid_activity_input"] || source["invalid_activity_input"]
    )
  end

  defp put_operational_feedback_fallbacks(source, callbacks, row) do
    source
    |> put_fallback(callbacks, row, "contact_success")
    |> put_fallback(callbacks, row, "contact_success_factor")
    |> put_fallback(callbacks, row, "contact_result")
    |> put_fallback(callbacks, row, "observation_success")
    |> put_fallback(callbacks, row, "observation_success_factor")
    |> put_fallback(callbacks, row, "observation_result")
    |> put_fallback(callbacks, row, "image_quality_score")
    |> put_fallback(callbacks, row, "product_quality_score")
    |> put_fallback(callbacks, row, "quality_score")
    |> put_fallback(callbacks, row, "image_quality_status")
    |> put_fallback(callbacks, row, "product_quality_status")
    |> put_fallback(callbacks, row, "quality_status")
    |> put_fallback(callbacks, row, "image_quality_source")
    |> put_fallback(callbacks, row, "product_quality_source")
    |> put_fallback(callbacks, row, "quality_source")
    |> put_fallback(callbacks, row, "cloud_cover_fraction")
    |> put_fallback(callbacks, row, "cloud_fraction")
    |> put_fallback(callbacks, row, "cloud_cover")
    |> put_fallback(callbacks, row, "blur_score")
    |> put_fallback(callbacks, row, "image_blur_score")
    |> put_fallback(callbacks, row, "sharpness_loss_fraction")
    |> put_fallback(callbacks, row, "command_success")
    |> put_fallback(callbacks, row, "command_success_factor")
    |> put_fallback(callbacks, row, "command_result")
    |> put_fallback(callbacks, row, "maneuver_success")
    |> put_fallback(callbacks, row, "maneuver_success_factor")
    |> put_fallback(callbacks, row, "maneuver_result")
    |> put_fallback(callbacks, row, "execution_uncertainty")
    |> put_fallback(callbacks, row, "execution_uncertainty_status")
    |> put_fallback(callbacks, row, "timing_3sigma_s")
    |> put_fallback(callbacks, row, "delta_v_3sigma_km_s")
    |> put_fallback(callbacks, row, "delta_v_3sigma_magnitude_km_s")
    |> put_fallback(callbacks, row, "execution_uncertainty_source")
    |> put_fallback(callbacks, row, "actual_throughput_mb")
    |> put_fallback(callbacks, row, "estimated_throughput_mb")
    |> put_fallback(callbacks, row, "required_downlink_mb")
  end

  defp put_operational_timeline_integrity_fallbacks(source, callbacks, row) do
    source
    |> put_fallback(callbacks, row, "dependency_activity_ids")
    |> put_fallback(callbacks, row, "dependency_timeline_ids")
    |> put_fallback(callbacks, row, "exclusive_with_activity_ids")
    |> put_fallback(callbacks, row, "exclusive_with_timeline_ids")
    |> put_fallback(callbacks, row, "exclusivity_group")
    |> put_fallback(callbacks, row, "missing_dependency_activity_ids")
    |> put_fallback(callbacks, row, "missing_dependency_timeline_ids")
    |> put_fallback(callbacks, row, "dependency_cycle_activity_ids")
    |> put_fallback(callbacks, row, "dependency_cycle_timeline_ids")
    |> put_fallback(callbacks, row, "dependency_order_violation_activity_ids")
    |> put_fallback(callbacks, row, "dependency_order_violation_timeline_ids")
    |> put_fallback(callbacks, row, "exclusivity_violation_activity_ids")
    |> put_fallback(callbacks, row, "exclusivity_violation_timeline_ids")
    |> put_fallback(callbacks, row, "exclusivity_violation_group")
  end

  defp put_feedback_weight_fallbacks(source, callbacks, row) do
    source
    |> put_fallback(callbacks, row, "feedback_weight")
    |> put_fallback(callbacks, row, "feedback_weight_source")
    |> put_fallback(callbacks, row, "feedback_sample_weight")
    |> put_fallback(callbacks, row, "feedback_sample_weight_source")
    |> put_fallback(callbacks, row, "sample_weight")
    |> put_fallback(callbacks, row, "sample_weight_source")
    |> put_fallback(callbacks, row, "confidence_weight")
    |> put_fallback(callbacks, row, "confidence_weight_source")
  end

  defp feedback_kind_activity_type("observation"), do: "observe"
  defp feedback_kind_activity_type("contact"), do: "contact"
  defp feedback_kind_activity_type("command"), do: "command"
  defp feedback_kind_activity_type("maneuver"), do: "maneuver"
  defp feedback_kind_activity_type(_kind), do: nil

  defp stringify_keys(row, callbacks), do: Keyword.fetch!(callbacks, :stringify_keys).(row)

  defp put_fallback(source, callbacks, row, field, row_field \\ nil),
    do:
      Keyword.fetch!(callbacks, :put_operator_review_row_fallback).(source, row, field, row_field)

  defp put_if_present(source, callbacks, key, value),
    do: Keyword.fetch!(callbacks, :put_if_present).(source, key, value)

  defp callbacks do
    [
      put_if_present: &put_if_present/3,
      put_operator_review_row_fallback: &put_operator_review_row_fallback/4,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp put_operator_review_row_fallback(source, row, field, row_field) do
    row_field = row_field || field

    case Map.get(source, field) do
      value when value in [nil, ""] -> put_if_present(source, field, row[row_field])
      _value -> source
    end
  end

  defp put_if_present(map, _key, value) when value in [nil, ""], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
