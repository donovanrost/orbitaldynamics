defmodule OrbitalDynamics.Schema.CollectionValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate_rows(issues, path, rows, validator) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      if is_map(row) do
        validator.(acc, "#{path}[#{index}]", row)
      else
        [PrimitiveValidation.error("#{path}[#{index}]", "must be an object") | acc]
      end
    end)
  end

  def validate_rows(issues, _path, _rows, _validator), do: issues

  def validate_optional_rows(issues, _path, nil, _validator), do: issues

  def validate_optional_rows(issues, path, rows, validator) when is_list(rows),
    do: validate_rows(issues, path, rows, validator)

  def validate_optional_rows(issues, path, _rows, _validator),
    do: [PrimitiveValidation.error(path, "must be a list") | issues]

  def validate_numeric_map(issues, _path, value) when value in [nil, :null], do: issues

  def validate_numeric_map(issues, path, %{} = values) do
    Enum.reduce(values, issues, fn {key, value}, acc ->
      if is_number(value),
        do: acc,
        else: [PrimitiveValidation.error("#{path}.#{key}", "must be a number") | acc]
    end)
  end

  def validate_numeric_map(issues, _path, _value), do: issues

  def validate_optional_string_list(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {value, index}, acc ->
          if is_binary(value),
            do: acc,
            else: [
              PrimitiveValidation.error("#{path}.#{field}[#{index}]", "must be a string") | acc
            ]
        end)

      _value ->
        issues
    end
  end
end
