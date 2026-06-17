defmodule OrbitalDynamics.Schema.OperationalFeedbackContracts do
  @moduledoc false

  @probability_map_fields [
    "contact_success_rate",
    "observation_success_rate",
    "image_quality_score",
    "cloud_cover_fraction",
    "blur_score",
    "maneuver_success_rate",
    "command_success_rate",
    "station_throughput_factor"
  ]

  @number_map_fields [
    "downlink_demand_mb",
    "target_priority_overrides"
  ]

  @string_map_fields [
    "image_quality_status",
    "image_quality_source"
  ]

  @string_list_map_fields ["downlink_demand_sources"]

  @object_map_fields [
    "downlink_demand_context",
    "maneuver_execution_uncertainty",
    "resource_margin_overrides",
    "resource_availability_overrides"
  ]

  def validate(issues, _path, nil, _callbacks), do: issues
  def validate(issues, _path, :null, _callbacks), do: issues

  def validate(issues, path, %{} = feedback, callbacks) when is_list(callbacks) do
    issues
    |> validate_probability_maps(callbacks, path, feedback, @probability_map_fields)
    |> validate_number_maps(callbacks, path, feedback, @number_map_fields)
    |> validate_string_maps(callbacks, path, feedback, @string_map_fields)
    |> validate_string_list_maps(callbacks, path, feedback, @string_list_map_fields)
    |> validate_object_maps(callbacks, path, feedback, @object_map_fields)
    |> validate_optional_rows(
      callbacks,
      "#{path}.operational_feedback.realized_activities",
      Map.get(feedback, "realized_activities"),
      fn acc, row_path, row -> validate_realized_activity(callbacks, acc, row_path, row) end
    )
  end

  def validate(issues, path, _feedback, callbacks),
    do: [error(callbacks, "#{path}.operational_feedback", "must be an object") | issues]

  defp validate_probability_maps(issues, callbacks, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, callbacks, path, feedback, field, fn entry_path, value, issues ->
        case value do
          value when is_number(value) and value >= 0.0 and value <= 1.0 ->
            issues

          value when is_number(value) ->
            [error(callbacks, entry_path, "must be between 0.0 and 1.0") | issues]

          _value ->
            [error(callbacks, entry_path, "must be a number") | issues]
        end
      end)
    end)
  end

  defp validate_number_maps(issues, callbacks, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, callbacks, path, feedback, field, fn entry_path, value, issues ->
        case value do
          value when is_number(value) and value >= 0.0 ->
            issues

          value when is_number(value) ->
            [error(callbacks, entry_path, "must be non-negative") | issues]

          _value ->
            [error(callbacks, entry_path, "must be a number") | issues]
        end
      end)
    end)
  end

  defp validate_string_maps(issues, callbacks, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, callbacks, path, feedback, field, fn entry_path, value, issues ->
        if is_binary(value) do
          issues
        else
          [error(callbacks, entry_path, "must be a string") | issues]
        end
      end)
    end)
  end

  defp validate_string_list_maps(issues, callbacks, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, callbacks, path, feedback, field, fn entry_path, value, issues ->
        cond do
          not is_list(value) ->
            [error(callbacks, entry_path, "must be an array") | issues]

          Enum.all?(value, &is_binary/1) ->
            issues

          true ->
            [error(callbacks, entry_path, "must contain only strings") | issues]
        end
      end)
    end)
  end

  defp validate_object_maps(issues, callbacks, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, callbacks, path, feedback, field, fn entry_path, value, issues ->
        if is_map(value) do
          issues
        else
          [error(callbacks, entry_path, "must be an object") | issues]
        end
      end)
    end)
  end

  defp validate_feedback_map(issues, callbacks, path, feedback, field, entry_validator) do
    case Map.get(feedback, field) do
      nil ->
        issues

      :null ->
        issues

      %{} = values ->
        Enum.reduce(values, issues, fn {key, value}, acc ->
          entry_validator.("#{path}.operational_feedback.#{field}.#{key}", value, acc)
        end)

      _value ->
        [error(callbacks, "#{path}.operational_feedback.#{field}", "must be an object") | issues]
    end
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp validate_realized_activity(callbacks, issues, path, activity),
    do: apply(require_callback(callbacks, :validate_realized_activity), [issues, path, activity])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
