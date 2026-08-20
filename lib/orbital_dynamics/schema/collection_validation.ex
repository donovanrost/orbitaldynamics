defmodule OrbitalDynamics.Schema.CollectionValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def proper_list?([]), do: true
  def proper_list?([_head | tail]), do: proper_list?(tail)
  def proper_list?(_value), do: false

  def sanitize_list_field(issues, path, map, field) when is_map(map) do
    case Map.fetch(map, field) do
      :error ->
        {issues, map}

      {:ok, value} ->
        cond do
          proper_list?(value) ->
            {issues, map}

          is_list(value) ->
            {
              [PrimitiveValidation.error("#{path}.#{field}", "must be a proper list") | issues],
              Map.put(map, field, [])
            }

          true ->
            {
              [PrimitiveValidation.error("#{path}.#{field}", "must be a list") | issues],
              Map.put(map, field, [])
            }
        end
    end
  end

  def validate_rows(issues, path, rows, validator) when is_list(rows) do
    if proper_list?(rows) do
      reduce_rows(issues, path, rows, validator)
    else
      [PrimitiveValidation.error(path, "must be a proper list") | issues]
    end
  end

  def validate_rows(issues, _path, _rows, _validator), do: issues

  defp reduce_rows(issues, path, rows, validator) do
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

  def validate_string_list_map(issues, path, map, field) do
    case Map.get(map, field) do
      %{} = grouped_values ->
        Enum.reduce(grouped_values, issues, fn {key, values}, acc ->
          entry_path = "#{path}.#{field}.#{key}"

          cond do
            not is_list(values) ->
              [PrimitiveValidation.error(entry_path, "must be an array") | acc]

            Enum.all?(values, &is_binary/1) ->
              acc

            true ->
              [PrimitiveValidation.error(entry_path, "must contain only strings") | acc]
          end
        end)

      _grouped_values ->
        issues
    end
  end

  def expect_list_count_equals(issues, path, row, count_field, list_field) do
    count = Map.get(row, count_field)
    values = Map.get(row, list_field)

    if Map.has_key?(row, count_field) and is_list(values) and count != length(values) do
      [
        PrimitiveValidation.error(
          "#{path}.#{count_field}",
          "must equal row-derived #{list_field} count"
        )
        | issues
      ]
    else
      issues
    end
  end

  def validate_ids_match_row_multiset(issues, path, report, field, expected_ids, message) do
    ids = Map.get(report, field)

    if is_list(ids) and Enum.sort(ids) != Enum.sort(expected_ids) do
      [PrimitiveValidation.error("#{path}.#{field}", message) | issues]
    else
      issues
    end
  end
end
