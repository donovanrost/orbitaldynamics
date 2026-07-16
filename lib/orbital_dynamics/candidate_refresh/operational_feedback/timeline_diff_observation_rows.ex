defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineDiffObservationRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def timeline_diff_changed_observation_quality_feedback_row?(%{} = row) do
    timeline_diff_status(row) == "changed" and
      timeline_diff_observation_activity?(row) and
      timeline_diff_changed_observation_target_id(row) not in [nil, ""] and
      (is_number(timeline_diff_changed_observation_image_quality_score(row)) or
         is_number(timeline_diff_changed_observation_cloud_cover_fraction(row)) or
         is_number(timeline_diff_changed_observation_blur_score(row)) or
         timeline_diff_changed_observation_image_quality_status(row) not in [nil, ""] or
         timeline_diff_changed_observation_image_quality_source(row) not in [nil, ""])
  end

  def timeline_diff_observation_activity?(row) do
    timeline_diff_observation_activity?(row, "source") or
      timeline_diff_observation_activity?(row, "replacement")
  end

  def timeline_diff_observation_activity?(row, side) do
    activity_type =
      row["#{side}_activity_type"] ||
        get_in(row, ["#{side}_activity_context", "activity_type"]) ||
        get_in(row, ["#{side}_activity_context", "type"])

    activity_type
    |> RowValues.normalized_token()
    |> case do
      type when type in ["observe", "observation", "target_visibility", "imaging"] -> true
      _type -> false
    end
  end

  def timeline_diff_changed_observation_target_id(row) do
    target_identity_value(
      row["replacement_target_id"] ||
        row["source_target_id"] ||
        get_in(row, ["replacement_activity_context", "target_id"]) ||
        get_in(row, ["source_activity_context", "target_id"]) ||
        get_in(row, ["replacement_activity_context", "target"]) ||
        get_in(row, ["source_activity_context", "target"]) ||
        get_in(row, ["replacement_activity_context", "timeline_identity", "subject_id"]) ||
        get_in(row, ["source_activity_context", "timeline_identity", "subject_id"])
    )
  end

  def timeline_diff_changed_observation_success_factor(row) do
    case RowValues.first_number(row, [
           "observation_success_factor",
           "replacement_observation_success_factor",
           ["replacement_activity_context", "observation_success_factor"]
         ]) do
      factor when is_number(factor) ->
        RowValues.unit_interval(factor)

      _factor ->
        timeline_diff_changed_observation_result_factor(row) ||
          timeline_diff_changed_source_observation_success_factor(row)
    end
  end

  def merge_changed_observation_quality_feedback(row, feedback) do
    target_id = timeline_diff_changed_observation_target_id(row)

    feedback
    |> put_timeline_diff_quality_number(
      "image_quality_score",
      target_id,
      timeline_diff_changed_observation_image_quality_score(row),
      :min
    )
    |> put_timeline_diff_quality_number(
      "cloud_cover_fraction",
      target_id,
      timeline_diff_changed_observation_cloud_cover_fraction(row),
      :max
    )
    |> put_timeline_diff_quality_number(
      "blur_score",
      target_id,
      timeline_diff_changed_observation_blur_score(row),
      :max
    )
    |> put_timeline_diff_quality_string(
      "image_quality_status",
      target_id,
      timeline_diff_changed_observation_image_quality_status(row)
    )
    |> put_timeline_diff_quality_string(
      "image_quality_source",
      target_id,
      timeline_diff_changed_observation_image_quality_source(row)
    )
  end

  defp timeline_diff_status(row), do: RowValues.normalized_token(row["diff_status"])

  defp timeline_diff_changed_observation_image_quality_score(row) do
    row
    |> RowValues.first_number([
      "image_quality_score",
      "replacement_image_quality_score",
      "replacement_product_quality_score",
      "replacement_quality_score",
      ["replacement_activity_context", "image_quality_score"],
      ["replacement_activity_context", "product_quality_score"],
      ["replacement_activity_context", "quality_score"],
      ["replacement_activity_context", "quality", "image_quality_score"],
      ["replacement_activity_context", "quality", "product_quality_score"],
      ["replacement_activity_context", "quality", "score"],
      "source_image_quality_score",
      "source_product_quality_score",
      "source_quality_score",
      ["source_activity_context", "image_quality_score"],
      ["source_activity_context", "product_quality_score"],
      ["source_activity_context", "quality_score"],
      ["source_activity_context", "quality", "image_quality_score"],
      ["source_activity_context", "quality", "product_quality_score"],
      ["source_activity_context", "quality", "score"]
    ])
    |> unit_interval_or_nil()
  end

  defp timeline_diff_changed_observation_cloud_cover_fraction(row) do
    row
    |> RowValues.first_number([
      "cloud_cover_fraction",
      "replacement_cloud_cover_fraction",
      "replacement_cloud_fraction",
      "replacement_cloud_cover",
      ["replacement_activity_context", "cloud_cover_fraction"],
      ["replacement_activity_context", "cloud_fraction"],
      ["replacement_activity_context", "cloud_cover"],
      ["replacement_activity_context", "quality", "cloud_cover_fraction"],
      ["replacement_activity_context", "quality", "cloud_fraction"],
      ["replacement_activity_context", "quality", "cloud_cover"],
      "source_cloud_cover_fraction",
      "source_cloud_fraction",
      "source_cloud_cover",
      ["source_activity_context", "cloud_cover_fraction"],
      ["source_activity_context", "cloud_fraction"],
      ["source_activity_context", "cloud_cover"],
      ["source_activity_context", "quality", "cloud_cover_fraction"],
      ["source_activity_context", "quality", "cloud_fraction"],
      ["source_activity_context", "quality", "cloud_cover"]
    ])
    |> unit_interval_or_nil()
  end

  defp timeline_diff_changed_observation_blur_score(row) do
    row
    |> RowValues.first_number([
      "blur_score",
      "replacement_blur_score",
      "replacement_image_blur_score",
      "replacement_sharpness_loss_fraction",
      ["replacement_activity_context", "blur_score"],
      ["replacement_activity_context", "image_blur_score"],
      ["replacement_activity_context", "sharpness_loss_fraction"],
      ["replacement_activity_context", "quality", "blur_score"],
      ["replacement_activity_context", "quality", "image_blur_score"],
      ["replacement_activity_context", "quality", "sharpness_loss_fraction"],
      "source_blur_score",
      "source_image_blur_score",
      "source_sharpness_loss_fraction",
      ["source_activity_context", "blur_score"],
      ["source_activity_context", "image_blur_score"],
      ["source_activity_context", "sharpness_loss_fraction"],
      ["source_activity_context", "quality", "blur_score"],
      ["source_activity_context", "quality", "image_blur_score"],
      ["source_activity_context", "quality", "sharpness_loss_fraction"]
    ])
    |> unit_interval_or_nil()
  end

  defp timeline_diff_changed_observation_image_quality_status(row) do
    first_string(row, [
      "image_quality_status",
      "replacement_image_quality_status",
      "replacement_product_quality_status",
      "replacement_quality_status",
      ["replacement_activity_context", "image_quality_status"],
      ["replacement_activity_context", "product_quality_status"],
      ["replacement_activity_context", "quality_status"],
      ["replacement_activity_context", "quality", "status"],
      "source_image_quality_status",
      "source_product_quality_status",
      "source_quality_status",
      ["source_activity_context", "image_quality_status"],
      ["source_activity_context", "product_quality_status"],
      ["source_activity_context", "quality_status"],
      ["source_activity_context", "quality", "status"]
    ])
  end

  defp timeline_diff_changed_observation_image_quality_source(row) do
    first_string(row, [
      "image_quality_source",
      "replacement_image_quality_source",
      "replacement_product_quality_source",
      "replacement_quality_source",
      ["replacement_activity_context", "image_quality_source"],
      ["replacement_activity_context", "product_quality_source"],
      ["replacement_activity_context", "quality_source"],
      ["replacement_activity_context", "quality", "source"],
      "source_image_quality_source",
      "source_product_quality_source",
      "source_quality_source",
      ["source_activity_context", "image_quality_source"],
      ["source_activity_context", "product_quality_source"],
      ["source_activity_context", "quality_source"],
      ["source_activity_context", "quality", "source"]
    ])
  end

  defp timeline_diff_changed_source_observation_success_factor(row) do
    case RowValues.first_number(row, [
           "source_observation_success_factor",
           ["source_activity_context", "observation_success_factor"]
         ]) do
      factor when is_number(factor) and factor < 1.0 -> RowValues.unit_interval(factor)
      _factor -> nil
    end
  end

  defp timeline_diff_changed_observation_result_factor(row) do
    cond do
      false in [
        row["observation_success"],
        row["replacement_observation_success"],
        get_in(row, ["replacement_activity_context", "observation_success"]),
        get_in(row, ["source_activity_context", "observation_success"])
      ] ->
        0.0

      RowValues.failure_token?(
        row["observation_result"] ||
          row["replacement_observation_result"] ||
          get_in(row, ["replacement_activity_context", "observation_result"]) ||
            get_in(row, ["source_activity_context", "observation_result"])
      ) ->
        0.0

      RowValues.failure_token?(
        row["replacement_status"] ||
          get_in(row, ["replacement_activity_context", "status"]) ||
            get_in(row, ["replacement_activity_context", "realized_status"])
      ) ->
        0.0

      true ->
        nil
    end
  end

  defp put_timeline_diff_quality_number(feedback, _field, _target_id, nil, _merge_mode),
    do: feedback

  defp put_timeline_diff_quality_number(feedback, field, target_id, value, :min) do
    update_in(feedback, [field], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(target_id, value, &min(&1, value))
    end)
  end

  defp put_timeline_diff_quality_number(feedback, field, target_id, value, :max) do
    update_in(feedback, [field], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(target_id, value, &max(&1, value))
    end)
  end

  defp put_timeline_diff_quality_string(feedback, _field, _target_id, nil), do: feedback

  defp put_timeline_diff_quality_string(feedback, field, target_id, value) do
    update_in(feedback, [field], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.put(target_id, value)
    end)
  end

  defp first_string(row, paths) do
    Enum.find_value(paths, fn
      path when is_list(path) ->
        row
        |> get_in(path)
        |> feedback_source_string()

      path ->
        row
        |> Map.get(path)
        |> feedback_source_string()
    end)
  end

  defp target_identity_value(%{} = target) do
    RowValues.stable_id_or_nil(target["id"] || target["target_id"] || target["name"]) ||
      RowValues.encode_value(target["id"] || target["target_id"] || target["name"])
  end

  defp target_identity_value(value), do: RowValues.encode_value(value)

  defp feedback_source_string(value) when is_binary(value) and value != "", do: value

  defp feedback_source_string(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp feedback_source_string(_value), do: nil

  defp unit_interval_or_nil(value) when is_number(value) and value >= 0.0 and value <= 1.0,
    do: value * 1.0

  defp unit_interval_or_nil(_value), do: nil
end
