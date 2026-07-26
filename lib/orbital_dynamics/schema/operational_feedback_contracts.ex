defmodule OrbitalDynamics.Schema.OperationalFeedbackContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_optional_rows: 4]
  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  alias OrbitalDynamics.Schema.RealizedActivityContracts

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

  def validate(issues, _path, nil), do: issues
  def validate(issues, _path, :null), do: issues

  def validate(issues, path, %{} = feedback) do
    validate_at(issues, "#{path}.operational_feedback", feedback)
  end

  def validate(issues, path, _feedback),
    do: [error("#{path}.operational_feedback", "must be an object") | issues]

  def validate_at(issues, _path, nil), do: issues
  def validate_at(issues, _path, :null), do: issues

  def validate_at(issues, path, %{} = feedback) do
    issues
    |> validate_probability_maps(path, feedback, @probability_map_fields)
    |> validate_number_maps(path, feedback, @number_map_fields)
    |> validate_string_maps(path, feedback, @string_map_fields)
    |> validate_string_list_maps(path, feedback, @string_list_map_fields)
    |> validate_object_maps(path, feedback, @object_map_fields)
    |> validate_optional_rows(
      "#{path}.realized_activities",
      Map.get(feedback, "realized_activities"),
      &RealizedActivityContracts.validate/3
    )
  end

  def validate_at(issues, path, _feedback), do: [error(path, "must be an object") | issues]

  defp validate_probability_maps(issues, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, path, feedback, field, fn entry_path, value, issues ->
        case value do
          value when is_number(value) and value >= 0.0 and value <= 1.0 ->
            issues

          value when is_number(value) ->
            [error(entry_path, "must be between 0.0 and 1.0") | issues]

          _value ->
            [error(entry_path, "must be a number") | issues]
        end
      end)
    end)
  end

  defp validate_number_maps(issues, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, path, feedback, field, fn entry_path, value, issues ->
        case value do
          value when is_number(value) and value >= 0.0 ->
            issues

          value when is_number(value) ->
            [error(entry_path, "must be non-negative") | issues]

          _value ->
            [error(entry_path, "must be a number") | issues]
        end
      end)
    end)
  end

  defp validate_string_maps(issues, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, path, feedback, field, fn entry_path, value, issues ->
        if is_binary(value) do
          issues
        else
          [error(entry_path, "must be a string") | issues]
        end
      end)
    end)
  end

  defp validate_string_list_maps(issues, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, path, feedback, field, fn entry_path, value, issues ->
        cond do
          not is_list(value) ->
            [error(entry_path, "must be an array") | issues]

          Enum.all?(value, &is_binary/1) ->
            issues

          true ->
            [error(entry_path, "must contain only strings") | issues]
        end
      end)
    end)
  end

  defp validate_object_maps(issues, path, feedback, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_feedback_map(acc, path, feedback, field, fn entry_path, value, issues ->
        if is_map(value) do
          issues
        else
          [error(entry_path, "must be an object") | issues]
        end
      end)
    end)
  end

  defp validate_feedback_map(issues, path, feedback, field, entry_validator) do
    case Map.get(feedback, field) do
      nil ->
        issues

      :null ->
        issues

      %{} = values ->
        Enum.reduce(values, issues, fn {key, value}, acc ->
          entry_validator.("#{path}.#{field}.#{key}", value, acc)
        end)

      _value ->
        [error("#{path}.#{field}", "must be an object") | issues]
    end
  end
end
