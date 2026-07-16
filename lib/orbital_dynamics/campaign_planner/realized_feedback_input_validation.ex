defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackInputValidation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    RealizedFeedbackWeights,
    ScalarValues,
    ValueEncoding
  }

  def invalid_input?(activity), do: invalid_input?(activity, default_callbacks())

  def invalid_input?(%{} = activity, callbacks) do
    activity
    |> invalid_identity_sections(callbacks)
    |> Kernel.!=([])
  end

  def invalid_input?(_activity, _callbacks), do: true

  def sections(realized_activities), do: sections(realized_activities, default_callbacks())

  def sections(realized_activities, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    realized_activities
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {activity, row_index} ->
      case stringify_keys.(activity) do
        %{} = activity ->
          (invalid_identity_sections(activity, callbacks) ++
             invalid_unit_interval_sections(activity, callbacks) ++
             invalid_nonnegative_number_sections(activity, callbacks))
          |> Enum.map(&Map.put(&1, "row_index", row_index))

        invalid_shape ->
          [
            %{
              "field" => "realized_activities",
              "row_index" => row_index,
              "reason" => "entry_must_be_object",
              "invalid_feedback_shape" => invalid_shape
            }
          ]
      end
    end)
  end

  defp invalid_unit_interval_sections(activity, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    activity
    |> unit_interval_values(callbacks)
    |> Enum.flat_map(fn {field, value} ->
      case unit_interval_number_status(value, callbacks) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "value_must_be_between_0_and_1",
              "invalid_feedback_value" => number,
              "row_id" => row_id(activity)
            }
            |> compact(callbacks)
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_unit_interval_number",
              "invalid_feedback_shape" => stringify_keys.(shape),
              "row_id" => row_id(activity)
            }
            |> compact(callbacks)
          ]
      end
    end)
  end

  defp invalid_nonnegative_number_sections(activity, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    activity
    |> nonnegative_number_values(callbacks)
    |> Enum.flat_map(fn {field, value} ->
      case nonnegative_number_status(value, callbacks) do
        {:ok, _value} ->
          []

        :missing ->
          []

        {:invalid_number, number} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => number,
              "row_id" => row_id(activity)
            }
            |> compact(callbacks)
          ]

        {:invalid_shape, shape} ->
          [
            %{
              "field" => "realized_activities.#{field}",
              "reason" => "entry_must_be_nonnegative_number",
              "invalid_feedback_shape" => stringify_keys.(shape),
              "row_id" => row_id(activity)
            }
            |> compact(callbacks)
          ]
      end
    end)
  end

  defp invalid_identity_sections(activity, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    activity
    |> identity_values()
    |> Enum.flat_map(fn {field, value} ->
      case raw_identifier(value) do
        nil ->
          []

        identifier ->
          if stable_id_string?.(identifier) do
            []
          else
            [
              %{
                "field" => "realized_activities.#{field}",
                "key" => identifier,
                "reason" => "key_must_be_stable_id",
                "row_id" => row_id(activity)
              }
              |> compact(callbacks)
            ]
          end
      end
    end)
  end

  defp nonnegative_number_values(activity, callbacks) do
    feedback_value_missing? = Keyword.fetch!(callbacks, :feedback_value_missing?)

    RealizedFeedbackWeights.fields()
    |> Enum.map(fn field -> {field, Map.get(activity, field)} end)
    |> Enum.reject(fn {_field, value} -> feedback_value_missing?.(value) end)
  end

  defp unit_interval_values(activity, callbacks) do
    feedback_value_missing? = Keyword.fetch!(callbacks, :feedback_value_missing?)

    [
      {"completed_fraction", activity["completed_fraction"]},
      {"image_quality_score", activity["image_quality_score"]},
      {"product_quality_score", activity["product_quality_score"]},
      {"quality_score", activity["quality_score"]},
      {"cloud_cover_fraction", activity["cloud_cover_fraction"]},
      {"cloud_fraction", activity["cloud_fraction"]},
      {"cloud_cover", activity["cloud_cover"]},
      {"blur_score", activity["blur_score"]},
      {"image_blur_score", activity["image_blur_score"]},
      {"sharpness_loss_fraction", activity["sharpness_loss_fraction"]},
      {"quality.image_quality_score", get_in(activity, ["quality", "image_quality_score"])},
      {"quality.product_quality_score", get_in(activity, ["quality", "product_quality_score"])},
      {"quality.score", get_in(activity, ["quality", "score"])},
      {"quality.cloud_cover_fraction", get_in(activity, ["quality", "cloud_cover_fraction"])},
      {"quality.cloud_fraction", get_in(activity, ["quality", "cloud_fraction"])},
      {"quality.cloud_cover", get_in(activity, ["quality", "cloud_cover"])},
      {"quality.blur_score", get_in(activity, ["quality", "blur_score"])},
      {"quality.image_blur_score", get_in(activity, ["quality", "image_blur_score"])},
      {"quality.sharpness_loss_fraction",
       get_in(activity, ["quality", "sharpness_loss_fraction"])},
      {"metadata.image_quality_score", get_in(activity, ["metadata", "image_quality_score"])},
      {"metadata.product_quality_score", get_in(activity, ["metadata", "product_quality_score"])},
      {"metadata.quality_score", get_in(activity, ["metadata", "quality_score"])},
      {"metadata.cloud_cover_fraction", get_in(activity, ["metadata", "cloud_cover_fraction"])},
      {"metadata.cloud_fraction", get_in(activity, ["metadata", "cloud_fraction"])},
      {"metadata.cloud_cover", get_in(activity, ["metadata", "cloud_cover"])},
      {"metadata.blur_score", get_in(activity, ["metadata", "blur_score"])},
      {"metadata.image_blur_score", get_in(activity, ["metadata", "image_blur_score"])},
      {"metadata.sharpness_loss_fraction",
       get_in(activity, ["metadata", "sharpness_loss_fraction"])}
    ]
    |> Enum.reject(fn {_field, value} -> feedback_value_missing?.(value) end)
  end

  defp identity_values(activity) do
    [
      {"id", activity["id"]},
      {"realized_activity_id", activity["realized_activity_id"]},
      {"planned_activity_id", activity["planned_activity_id"]},
      {"activity_id", activity["activity_id"]},
      {"timeline_id", activity["timeline_id"]},
      {"metadata.timeline_id", get_in(activity, ["metadata", "timeline_id"])},
      {"scenario_id", activity["scenario_id"]},
      {"metadata.scenario_id", get_in(activity, ["metadata", "scenario_id"])},
      {"ground_station_id", activity["ground_station_id"]},
      {"station_id", activity["station_id"]},
      {"metadata.ground_station_id", get_in(activity, ["metadata", "ground_station_id"])},
      {"metadata.station_id", get_in(activity, ["metadata", "station_id"])},
      {"target_id", activity["target_id"]},
      {"metadata.target_id", get_in(activity, ["metadata", "target_id"])},
      {"spacecraft_id", activity["spacecraft_id"]},
      {"satellite_id", activity["satellite_id"]},
      {"metadata.spacecraft_id", get_in(activity, ["metadata", "spacecraft_id"])},
      {"resource_id", activity["resource_id"]},
      {"source_window_id", activity["source_window_id"]},
      {"metadata.source_window_id", get_in(activity, ["metadata", "source_window_id"])},
      {"target.id", nested_identifier(activity, "target", ["target_id", "id"])},
      {"station.id", nested_identifier(activity, "station", ["station_id", "id"])},
      {"ground_station.id",
       nested_identifier(activity, "ground_station", ["ground_station_id", "station_id", "id"])},
      {"spacecraft.id", nested_identifier(activity, "spacecraft", ["spacecraft_id", "id"])},
      {"satellite.id", nested_identifier(activity, "satellite", ["satellite_id", "id"])},
      {"source_window.id",
       nested_identifier(activity, "source_window", ["source_window_id", "id"])}
    ]
  end

  defp row_id(activity) do
    raw_identifier(activity["id"]) ||
      raw_identifier(activity["realized_activity_id"]) ||
      raw_identifier(activity["activity_id"])
  end

  defp nested_identifier(activity, object_key, identity_keys) do
    case Map.get(activity, object_key) do
      %{} = object -> Enum.find_value(identity_keys, &Map.get(object, &1))
      _value -> nil
    end
  end

  defp raw_identifier(nil), do: nil
  defp raw_identifier(value) when is_binary(value) and value != "", do: value
  defp raw_identifier(value) when is_atom(value), do: Atom.to_string(value)
  defp raw_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp raw_identifier(_value), do: nil

  defp unit_interval_number_status(value, callbacks) do
    FeedbackNumericValues.unit_interval_number_status(
      value,
      feedback_numeric_callbacks(callbacks)
    )
  end

  defp nonnegative_number_status(value, callbacks) do
    FeedbackNumericValues.nonnegative_number_status(value, feedback_numeric_callbacks(callbacks))
  end

  defp feedback_numeric_callbacks(callbacks),
    do: [
      numeric_or_nil: Keyword.fetch!(callbacks, :numeric_or_nil),
      feedback_value_missing?: Keyword.fetch!(callbacks, :feedback_value_missing?)
    ]

  defp compact(map, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    compact_map.(map)
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      feedback_value_missing?: &feedback_value_missing?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]
  end

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
