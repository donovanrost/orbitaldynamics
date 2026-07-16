defmodule OrbitalDynamics.Schema.PrimitiveValidation do
  @moduledoc false

  def expect_type(issues, path, map, field, type) do
    if matches_type?(Map.get(map, field), type) do
      issues
    else
      [error("#{path}.#{field}", "must be a #{type}") | issues]
    end
  end

  def expect_optional_type(issues, path, map, field, type) do
    case Map.get(map, field) do
      nil ->
        issues

      :null ->
        issues

      value ->
        if matches_type?(value, type) do
          issues
        else
          [error("#{path}.#{field}", "must be a #{type}") | issues]
        end
    end
  end

  def expect_optional_list(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      value when is_list(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a list") | issues]
    end
  end

  def expect_number(issues, path, map, field) do
    if is_number(Map.get(map, field)) do
      issues
    else
      [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_field_at_least(issues, _path, _map, _field, nil), do: issues

  def expect_field_at_least(issues, path, map, field, minimum) do
    value = Map.get(map, field)

    if Map.has_key?(map, field) and is_number(value) and value < minimum do
      [error("#{path}.#{field}", "must be at least #{minimum}") | issues]
    else
      issues
    end
  end

  def expect_optional_number(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_number(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_optional_number_or_string(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_number(value) or is_binary(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a number or string") | issues]
    end
  end

  def expect_optional_non_negative_number(issues, path, map, field) do
    case Map.get(map, field) do
      nil ->
        issues

      :null ->
        issues

      value when is_number(value) and value >= 0.0 ->
        issues

      value when is_number(value) ->
        [error("#{path}.#{field}", "must be non-negative") | issues]

      _value ->
        [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_optional_integer(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_integer(value) -> issues
      _value -> [error("#{path}.#{field}", "must be an integer") | issues]
    end
  end

  def expect_probability_range(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        issues

      value when is_number(value) ->
        [error("#{path}.#{field}", "must be between 0.0 and 1.0") | issues]

      _value ->
        issues
    end
  end

  def expect_optional_probability(issues, path, map, field) do
    case Map.get(map, field) do
      nil ->
        issues

      :null ->
        issues

      value when is_number(value) and value >= 0.0 and value <= 1.0 ->
        issues

      value when is_number(value) ->
        [error("#{path}.#{field}", "must be between 0.0 and 1.0") | issues]

      _value ->
        [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  def expect_equal(issues, path, map, field, expected) do
    if Map.get(map, field) == expected do
      issues
    else
      [error("#{path}.#{field}", "must equal #{inspect(expected)}") | issues]
    end
  end

  def expect_one_of(issues, path, map, field, allowed) do
    if Map.get(map, field) in allowed do
      issues
    else
      [error("#{path}.#{field}", "must be one of #{inspect(allowed)}") | issues]
    end
  end

  def expect_optional_one_of(issues, path, map, field, allowed) do
    case Map.get(map, field) do
      nil ->
        issues

      value ->
        if value in allowed,
          do: issues,
          else: [error("#{path}.#{field}", "must be one of #{inspect(allowed)}") | issues]
    end
  end

  def expect_optional_number_or_number_list(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value when is_number(value) -> issues
      values when is_list(values) -> validate_number_list_items(issues, path, map, field)
      _value -> [error("#{path}.#{field}", "must be a number or list of numbers") | issues]
    end
  end

  def validate_string_list_items(issues, path, map, field) do
    case Map.get(map, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {value, index}, acc ->
          if is_binary(value),
            do: acc,
            else: [error("#{path}.#{field}[#{index}]", "must be a string") | acc]
        end)

      _value ->
        issues
    end
  end

  def validate_number_list_items(issues, path, map, field) do
    case Map.get(map, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {value, index}, acc ->
          if is_number(value),
            do: acc,
            else: [error("#{path}.#{field}[#{index}]", "must be a number") | acc]
        end)

      _value ->
        issues
    end
  end

  def validate_non_negative_integer_list_items(issues, path, map, field) do
    case Map.get(map, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {value, index}, acc ->
          if is_integer(value) and value >= 0,
            do: acc,
            else: [error("#{path}.#{field}[#{index}]", "must be a non-negative integer") | acc]
        end)

      _value ->
        issues
    end
  end

  def validate_optional_string_lists(issues, path, map, fields),
    do: Enum.reduce(fields, issues, &validate_string_list_items(&2, path, map, &1))

  def validate_optional_string_or_array_fields(issues, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      case Map.get(map, field) do
        nil -> acc
        :null -> acc
        value when is_binary(value) -> acc
        values when is_list(values) -> validate_string_list_items(acc, path, map, field)
        _value -> [error("#{path}.#{field}", "must be a string or a list of strings") | acc]
      end
    end)
  end

  def validate_optional_string_fields(issues, path, map, fields),
    do: Enum.reduce(fields, issues, &expect_optional_type(&2, path, map, &1, :binary))

  def validate_optional_number_fields(issues, path, map, fields),
    do: Enum.reduce(fields, issues, &expect_optional_number(&2, path, map, &1))

  def validate_optional_integer_fields(issues, path, map, fields),
    do: Enum.reduce(fields, issues, &expect_optional_integer(&2, path, map, &1))

  def validate_optional_boolean_fields(issues, path, map, fields),
    do: Enum.reduce(fields, issues, &expect_optional_type(&2, path, map, &1, :boolean))

  def validate_string_list_allowed(issues, path, map, field, allowed) do
    case Map.get(map, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {value, index}, acc ->
          cond do
            not is_binary(value) ->
              [error("#{path}.#{field}[#{index}]", "must be a string") | acc]

            value not in allowed ->
              [error("#{path}.#{field}[#{index}]", "must be one of #{inspect(allowed)}") | acc]

            true ->
              acc
          end
        end)

      _value ->
        issues
    end
  end

  def require_fields(issues, path, map, fields) when is_map(map) do
    Enum.reduce(fields, issues, fn field, acc ->
      if Map.has_key?(map, field), do: acc, else: [error("#{path}.#{field}", "is required") | acc]
    end)
  end

  def require_nested(issues, path, map, fields) when is_map(map),
    do: require_fields(issues, path, map, fields)

  def require_nested(issues, path, _value, _fields),
    do: [error(path, "must be an object") | issues]

  def expect_number_vector(issues, path, value) do
    if is_list(value) and length(value) == 3 and Enum.all?(value, &is_number/1) do
      issues
    else
      [error(path, "must be a three-element number array") | issues]
    end
  end

  def expect_optional_number_vector(issues, path, map, field) do
    case Map.get(map, field) do
      nil -> issues
      :null -> issues
      value -> expect_number_vector(issues, "#{path}.#{field}", value)
    end
  end

  def validate_interval(issues, path, %{"starts_at_s" => start_s, "ends_at_s" => end_s})
      when is_number(start_s) and is_number(end_s) do
    if end_s >= start_s do
      issues
    else
      [error(path, "ends_at_s must be greater than or equal to starts_at_s") | issues]
    end
  end

  def validate_interval(issues, _path, _activity), do: issues

  def error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end

  defp matches_type?(value, :map), do: is_map(value)
  defp matches_type?(value, :list), do: is_list(value)
  defp matches_type?(value, :binary), do: is_binary(value)
  defp matches_type?(value, :boolean), do: is_boolean(value)
  defp matches_type?(value, :integer), do: is_integer(value)
end
