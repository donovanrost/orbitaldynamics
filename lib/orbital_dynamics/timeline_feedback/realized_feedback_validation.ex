defmodule OrbitalDynamics.TimelineFeedback.RealizedFeedbackValidation do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{ArtifactValue, SuccessFactor}

  def invalid_realized_feedback_unit_interval_sections(activity) do
    realized_feedback_unit_interval_paths()
    |> Enum.flat_map(fn {field, path} ->
      value = feedback_path_value(activity, path)

      case unit_interval_number_status(value) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => number
            }
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => stringify_keys(shape)
            }
          ]
      end
    end)
  end

  def invalid_realized_feedback_nonnegative_number_sections(activity) do
    realized_feedback_weight_paths()
    |> Enum.flat_map(fn {field, path} ->
      value = feedback_path_value(activity, path)

      case nonnegative_number_status(value) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => number
            }
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => field,
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => stringify_keys(shape)
            }
          ]
      end
    end)
  end

  def sanitize_realized_feedback_unit_interval_values(activity) do
    realized_feedback_unit_interval_paths()
    |> Enum.reduce(activity, fn {_field, path}, sanitized ->
      value = feedback_path_value(sanitized, path)

      case unit_interval_number_status(value) do
        {:invalid_number, _number} -> delete_feedback_path(sanitized, path)
        {:invalid_shape, _shape} -> delete_feedback_path(sanitized, path)
        _status -> sanitized
      end
    end)
    |> sanitize_realized_feedback_factor_sources(activity)
    |> sanitize_realized_feedback_weight_values(activity)
  end

  defp sanitize_realized_feedback_weight_values(sanitized, source_activity) do
    sanitized =
      realized_feedback_weight_paths()
      |> Enum.reduce(sanitized, fn {_field, path}, sanitized ->
        value = feedback_path_value(sanitized, path)

        case nonnegative_number_status(value) do
          {:invalid_number, _number} -> delete_feedback_path(sanitized, path)
          {:invalid_shape, _shape} -> delete_feedback_path(sanitized, path)
          _status -> sanitized
        end
      end)

    if invalid_realized_feedback_weight?(source_activity) and
         not valid_realized_feedback_weight?(sanitized) do
      [
        ["feedback_weight_source"],
        ["feedback_sample_weight_source"],
        ["sample_weight_source"],
        ["confidence_weight_source"]
      ]
      |> Enum.reduce(sanitized, &delete_feedback_path(&2, &1))
    else
      sanitized
    end
  end

  defp sanitize_realized_feedback_factor_sources(sanitized, source_activity) do
    [
      {"contact_success_factor",
       [
         ["contact_success_factor_source"],
         ["metadata", "contact_success_factor_source"],
         ["throughput_model", "confidence_source"]
       ]},
      {"command_success_factor",
       [["command_success_factor_source"], ["metadata", "command_success_factor_source"]]},
      {"observation_success_factor",
       [["observation_success_factor_source"], ["metadata", "observation_success_factor_source"]]},
      {"maneuver_success_factor",
       [["maneuver_success_factor_source"], ["metadata", "maneuver_success_factor_source"]]}
    ]
    |> Enum.reduce(sanitized, fn {field, source_paths}, sanitized ->
      if invalid_realized_feedback_field?(source_activity, field) and
           not valid_realized_feedback_field?(sanitized, field) do
        Enum.reduce(source_paths, sanitized, &delete_feedback_path(&2, &1))
      else
        sanitized
      end
    end)
  end

  defp invalid_realized_feedback_field?(activity, field) do
    realized_feedback_unit_interval_paths()
    |> Enum.filter(fn {candidate_field, _path} -> candidate_field == field end)
    |> Enum.any?(fn {_field, path} ->
      case unit_interval_number_status(feedback_path_value(activity, path)) do
        {:invalid_number, _number} -> true
        {:invalid_shape, _shape} -> true
        _status -> false
      end
    end)
  end

  defp valid_realized_feedback_field?(activity, field) do
    realized_feedback_unit_interval_paths()
    |> Enum.filter(fn {candidate_field, _path} -> candidate_field == field end)
    |> Enum.any?(fn {_field, path} ->
      case unit_interval_number_status(feedback_path_value(activity, path)) do
        {:ok, _number} -> true
        _status -> false
      end
    end)
  end

  defp realized_feedback_unit_interval_paths do
    [
      {"contact_success_factor", ["contact_success_factor"]},
      {"contact_success_factor", ["metadata", "contact_success_factor"]},
      {"contact_success_factor", ["throughput_model", "contact_success_factor"]},
      {"command_success_factor", ["command_success_factor"]},
      {"command_success_factor", ["metadata", "command_success_factor"]},
      {"observation_success_factor", ["observation_success_factor"]},
      {"observation_success_factor", ["metadata", "observation_success_factor"]},
      {"maneuver_success_factor", ["maneuver_success_factor"]},
      {"maneuver_success_factor", ["metadata", "maneuver_success_factor"]},
      {"completed_fraction", ["completed_fraction"]},
      {"capacity_pack_capacity_fraction", ["capacity_pack_capacity_fraction"]},
      {"image_quality_score", ["image_quality_score"]},
      {"image_quality_score", ["product_quality_score"]},
      {"image_quality_score", ["quality_score"]},
      {"image_quality_score", ["metadata", "image_quality_score"]},
      {"image_quality_score", ["metadata", "product_quality_score"]},
      {"image_quality_score", ["metadata", "quality_score"]},
      {"cloud_cover_fraction", ["cloud_cover_fraction"]},
      {"cloud_cover_fraction", ["cloud_fraction"]},
      {"cloud_cover_fraction", ["cloud_cover"]},
      {"cloud_cover_fraction", ["metadata", "cloud_cover_fraction"]},
      {"cloud_cover_fraction", ["metadata", "cloud_fraction"]},
      {"cloud_cover_fraction", ["metadata", "cloud_cover"]},
      {"blur_score", ["blur_score"]},
      {"blur_score", ["image_blur_score"]},
      {"blur_score", ["sharpness_loss_fraction"]},
      {"blur_score", ["metadata", "blur_score"]},
      {"blur_score", ["metadata", "image_blur_score"]},
      {"blur_score", ["metadata", "sharpness_loss_fraction"]}
    ]
  end

  defp realized_feedback_weight_paths do
    [
      {"feedback_weight", ["feedback_weight"]},
      {"feedback_sample_weight", ["feedback_sample_weight"]},
      {"sample_weight", ["sample_weight"]},
      {"confidence_weight", ["confidence_weight"]}
    ]
  end

  defp invalid_realized_feedback_weight?(activity) do
    realized_feedback_weight_paths()
    |> Enum.any?(fn {_field, path} ->
      case nonnegative_number_status(feedback_path_value(activity, path)) do
        {:invalid_number, _number} -> true
        {:invalid_shape, _shape} -> true
        _status -> false
      end
    end)
  end

  defp valid_realized_feedback_weight?(activity) do
    realized_feedback_weight_paths()
    |> Enum.any?(fn {_field, path} ->
      case nonnegative_number_status(feedback_path_value(activity, path)) do
        {:ok, _number} -> true
        _status -> false
      end
    end)
  end

  def put_invalid_realized_feedback_sections(row, []), do: row

  def put_invalid_realized_feedback_sections(row, invalid_sections) do
    reason = invalid_realized_feedback_input_reason(invalid_sections)

    context =
      row
      |> Map.get("realized_activity_context", %{})
      |> Map.put("invalid_realized_feedback_input", true)
      |> Map.put("invalid_realized_feedback_input_reason", reason)
      |> Map.put("invalid_realized_feedback_sections", invalid_sections)

    row
    |> Map.put("invalid_realized_feedback_input", true)
    |> Map.put("invalid_realized_feedback_input_reason", reason)
    |> Map.put("invalid_realized_feedback_sections", invalid_sections)
    |> Map.put("realized_activity_context", context)
  end

  defp invalid_realized_feedback_input_reason(invalid_sections) do
    if Enum.all?(
         invalid_sections,
         &(&1["reason"] == "entry_must_be_unit_interval_number")
       ) do
      "realized_feedback_unit_interval_sections_invalid"
    else
      "realized_feedback_sections_invalid"
    end
  end

  defp feedback_path_value(%{} = map, [key]), do: Map.get(map, key)

  defp feedback_path_value(%{} = map, [key | rest]) do
    case Map.get(map, key) do
      %{} = nested -> feedback_path_value(nested, rest)
      _value -> nil
    end
  end

  defp feedback_path_value(_value, _path), do: nil

  defp delete_feedback_path(%{} = map, [key]), do: Map.delete(map, key)

  defp delete_feedback_path(%{} = map, [key | rest]) do
    case Map.get(map, key) do
      %{} = nested ->
        nested = delete_feedback_path(nested, rest)

        if map_size(nested) == 0 do
          Map.delete(map, key)
        else
          Map.put(map, key, nested)
        end

      _value ->
        map
    end
  end

  defp delete_feedback_path(value, _path), do: value

  defp unit_interval_number_status(value),
    do: SuccessFactor.unit_interval_number_status(value)

  defp nonnegative_number_status(value),
    do: SuccessFactor.nonnegative_number_status(value)

  defp stringify_keys(value), do: ArtifactValue.stringify_keys(value)
end
