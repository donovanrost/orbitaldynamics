defmodule OrbitalDynamics.Schema.StableIdValidation do
  @moduledoc false

  @stable_id_pattern "^[A-Za-z0-9][A-Za-z0-9._:@-]*(?![\\s\\S])"
  @stable_id_regex ~r/\A[A-Za-z0-9][A-Za-z0-9._:@-]*\z/

  def pattern, do: @stable_id_pattern

  def valid?(value) when is_binary(value),
    do: String.valid?(value) and Regex.match?(@stable_id_regex, value)

  def valid?(_value), do: false

  def validate_stable_ids(issues, path, map, fields) when is_map(map) do
    Enum.reduce(fields, issues, fn field, acc ->
      if Map.has_key?(map, field) do
        validate_stable_id(acc, "#{path}.#{field}", Map.get(map, field))
      else
        acc
      end
    end)
  end

  def validate_stable_ids(issues, _path, _value, _fields), do: issues

  def validate_optional_stable_ids(issues, path, map, fields) when is_map(map) do
    Enum.reduce(fields, issues, fn field, acc ->
      case Map.get(map, field) do
        nil -> acc
        :null -> acc
        value -> validate_stable_id(acc, "#{path}.#{field}", value)
      end
    end)
  end

  def validate_stable_id_list(issues, path, values) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {value, index}, acc ->
      validate_stable_id(acc, "#{path}[#{index}]", value)
    end)
  end

  def validate_stable_id_list(issues, _path, _values), do: issues

  def validate_stable_id_list(issues, path, map, field) do
    case Map.get(map, field) do
      values when is_list(values) -> validate_stable_id_list(issues, "#{path}.#{field}", values)
      _value -> issues
    end
  end

  def validate_stable_id_array_map(issues, _path, value) when value in [nil, :null],
    do: issues

  def validate_stable_id_array_map(issues, path, %{} = values) do
    Enum.reduce(values, issues, fn {key, refs}, acc ->
      validate_stable_id_list(acc, "#{path}.#{key}", refs)
    end)
  end

  def validate_stable_id_array_map(issues, _path, _value), do: issues

  def validate_nested_stable_id_array_map(issues, _path, value) when value in [nil, :null],
    do: issues

  def validate_nested_stable_id_array_map(issues, path, %{} = values) do
    Enum.reduce(values, issues, fn {key, nested_values}, acc ->
      validate_stable_id_array_map(acc, "#{path}.#{key}", nested_values)
    end)
  end

  def validate_nested_stable_id_array_map(issues, _path, _value), do: issues

  def validate_optional_stable_id_list(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      values when is_list(values) -> validate_stable_id_list(issues, "#{path}.#{field}", values)
      _value -> issues
    end
  end

  def validate_nested_id_match(
        issues,
        path,
        row,
        nested_field,
        nested_id_field,
        expected_field,
        message
      ) do
    nested = Map.get(row, nested_field)
    expected = Map.get(row, expected_field)

    if is_map(nested) and expected != nil and Map.get(nested, nested_id_field) != expected do
      [error("#{path}.#{nested_field}.#{nested_id_field}", message) | issues]
    else
      issues
    end
  end

  def validate_stable_id(issues, path, value) when is_binary(value) do
    if valid?(value) do
      issues
    else
      [error(path, "must match stable ID pattern #{@stable_id_pattern}") | issues]
    end
  end

  def validate_stable_id(issues, path, _value),
    do: [error(path, "must be a stable ID string") | issues]

  def reject_duplicate_ids(issues, path, ids) do
    duplicate_ids =
      ids
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> id end)
      |> Enum.sort()

    if duplicate_ids == [] do
      issues
    else
      [error(path, "must not contain duplicate IDs: #{inspect(duplicate_ids)}") | issues]
    end
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
