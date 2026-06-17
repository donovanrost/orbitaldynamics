defmodule OrbitalDynamics.Schema.ManifestFieldReferenceContracts do
  @moduledoc false

  def validate(issues, path, artifact, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      artifact,
      "reference_mode",
      "study_manifest_schema_field_reference"
    )
    |> expect_equal(callbacks, path, artifact, "schema_version", 1)
    |> expect_non_negative_integer(callbacks, path, artifact, "field_count")
    |> expect_type(callbacks, path, artifact, "fields", :list)
    |> expect_type(callbacks, path, artifact, "top_level_required", :list)
    |> expect_type(callbacks, path, artifact, "activation_sections", :list)
    |> expect_type(callbacks, path, artifact, "supported", :map)
    |> expect_type(
      callbacks,
      path <> ".supported",
      Map.get(artifact, "supported", %{}),
      "lint_error_codes",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path <> ".supported",
      Map.get(artifact, "supported", %{}),
      "lint_error_codes"
    )
    |> validate_rows(path, artifact, callbacks)
  end

  defp validate_rows(issues, path, artifact, callbacks) do
    case Map.get(artifact, "fields") do
      fields when is_list(fields) ->
        row_paths =
          fields
          |> Enum.filter(&is_map/1)
          |> Enum.map(&Map.get(&1, "path"))
          |> Enum.filter(&is_binary/1)

        path_set = MapSet.new(row_paths)
        rows_by_path = Map.new(Enum.filter(fields, &is_map/1), &{Map.get(&1, "path"), &1})

        issues
        |> expect_field_equals(callbacks, path, artifact, "field_count", length(fields))
        |> validate_duplicate_paths(callbacks, path, row_paths)
        |> validate_top_level_required(callbacks, path, artifact, rows_by_path)
        |> validate_activation_sections(callbacks, path, artifact, rows_by_path)
        |> validate_supported_vocabularies(callbacks, path, artifact, rows_by_path)
        |> validate_row_integrity(callbacks, path, fields, path_set)

      _fields ->
        issues
    end
  end

  defp validate_row_integrity(issues, callbacks, path, fields, path_set) do
    fields
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc ->
        row_path = "#{path}.fields[#{index}]"

        acc
        |> require_fields(callbacks, row_path, row, [
          "path",
          "parent_path",
          "section",
          "type",
          "required",
          "array_item"
        ])
        |> expect_type(callbacks, row_path, row, "path", :binary)
        |> expect_type(callbacks, row_path, row, "parent_path", :binary)
        |> expect_type(callbacks, row_path, row, "section", :binary)
        |> validate_row_type(callbacks, row_path, row)
        |> expect_type(callbacks, row_path, row, "required", :boolean)
        |> expect_type(callbacks, row_path, row, "array_item", :boolean)
        |> validate_parent_path(callbacks, row_path, row, path_set)
        |> validate_section(callbacks, row_path, row)
        |> validate_array_item(callbacks, row_path, row)

      {_row, index}, acc ->
        [error(callbacks, "#{path}.fields[#{index}]", "must be an object") | acc]
    end)
  end

  defp validate_duplicate_paths(issues, callbacks, path, row_paths) do
    row_paths
    |> Enum.frequencies()
    |> Enum.filter(fn {_row_path, count} -> count > 1 end)
    |> Enum.reduce(issues, fn {duplicate_path, _count}, acc ->
      [
        error(
          callbacks,
          "#{path}.fields",
          "contains duplicate field path #{inspect(duplicate_path)}"
        )
        | acc
      ]
    end)
  end

  defp validate_top_level_required(issues, callbacks, path, artifact, rows_by_path) do
    case Map.get(artifact, "top_level_required") do
      fields when is_list(fields) ->
        issues
        |> validate_top_level_required_fields(callbacks, path, fields, rows_by_path)
        |> expect_string_list_set_equals(
          callbacks,
          path <> ".top_level_required",
          fields,
          top_level_required(rows_by_path),
          "must equal row-derived top-level required fields"
        )

      _fields ->
        issues
    end
  end

  defp validate_top_level_required_fields(issues, callbacks, path, fields, rows_by_path) do
    fields
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {field, index}, acc when is_binary(field) ->
        validate_top_level_required_field(acc, callbacks, path, index, field, rows_by_path)

      {_field, index}, acc ->
        [error(callbacks, "#{path}.top_level_required[#{index}]", "must be a string") | acc]
    end)
  end

  defp top_level_required(rows_by_path) do
    rows_by_path
    |> Map.values()
    |> Enum.filter(&(Map.get(&1, "parent_path") == "$" and Map.get(&1, "required") == true))
    |> Enum.map(&(&1 |> Map.fetch!("path") |> String.trim_leading("$.")))
    |> Enum.sort()
  end

  defp validate_top_level_required_field(issues, callbacks, path, index, field, rows_by_path) do
    row = Map.get(rows_by_path, "$.#{field}")

    cond do
      not is_map(row) ->
        [
          error(
            callbacks,
            "#{path}.top_level_required[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "parent_path") != "$" ->
        [
          error(
            callbacks,
            "#{path}.top_level_required[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "required") != true ->
        [
          error(
            callbacks,
            "#{path}.top_level_required[#{index}]",
            "must reference a required field row"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_activation_sections(issues, callbacks, path, artifact, rows_by_path) do
    case Map.get(artifact, "activation_sections") do
      sections when is_list(sections) ->
        validate_activation_section_entries(issues, callbacks, path, sections, rows_by_path)

      _sections ->
        issues
    end
  end

  defp validate_activation_section_entries(issues, callbacks, path, sections, rows_by_path) do
    sections
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {section, index}, acc when is_binary(section) ->
        validate_activation_section(acc, callbacks, path, index, section, rows_by_path)

      {_section, index}, acc ->
        [error(callbacks, "#{path}.activation_sections[#{index}]", "must be a string") | acc]
    end)
  end

  defp validate_activation_section(issues, callbacks, path, index, section, rows_by_path) do
    row = Map.get(rows_by_path, "$.#{section}")

    cond do
      not is_map(row) ->
        [
          error(
            callbacks,
            "#{path}.activation_sections[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "parent_path") != "$" ->
        [
          error(
            callbacks,
            "#{path}.activation_sections[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "section") != section ->
        [
          error(
            callbacks,
            "#{path}.activation_sections[#{index}]",
            "must match the activated field section"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_supported_vocabularies(issues, callbacks, path, artifact, rows_by_path) do
    supported = Map.get(artifact, "supported", %{})

    issues
    |> validate_supported_enum(
      callbacks,
      "#{path}.supported",
      supported,
      "outputs",
      Map.get(rows_by_path, "$.outputs.[]")
    )
    |> validate_supported_enum(
      callbacks,
      "#{path}.supported",
      supported,
      "propagators",
      Map.get(rows_by_path, "$.propagator")
    )
    |> validate_supported_enum(
      callbacks,
      "#{path}.supported",
      supported,
      "search_objectives",
      Map.get(rows_by_path, "$.search.objective")
    )
    |> validate_supported_enum(
      callbacks,
      "#{path}.supported",
      supported,
      "search_objectives",
      Map.get(rows_by_path, "$.monte_carlo.objective")
    )
  end

  defp validate_supported_enum(issues, callbacks, path, supported, field, row)
       when is_map(supported) and is_map(row) do
    case {Map.get(supported, field), Map.get(row, "enum")} do
      {values, enum_values} when is_list(values) and is_list(enum_values) ->
        cond do
          not Enum.all?(values, &is_binary/1) ->
            [error(callbacks, "#{path}.#{field}", "must be a list of strings") | issues]

          Enum.sort(values) == Enum.sort(enum_values) ->
            issues

          true ->
            [
              error(callbacks, "#{path}.#{field}", "must match manifest schema enum values")
              | issues
            ]
        end

      {values, _enum_values} when is_list(values) ->
        [
          error(callbacks, "#{path}.#{field}", "must have matching manifest field enum evidence")
          | issues
        ]

      {_values, _enum_values} ->
        [error(callbacks, "#{path}.#{field}", "must be a list") | issues]
    end
  end

  defp validate_supported_enum(issues, callbacks, path, supported, field, _row)
       when is_map(supported) do
    [
      error(callbacks, "#{path}.#{field}", "must have matching manifest field enum evidence")
      | issues
    ]
  end

  defp validate_supported_enum(issues, _callbacks, _path, _supported, _field, _row), do: issues

  defp expect_string_list_set_equals(issues, callbacks, path, values, expected, message) do
    cond do
      not is_list(values) ->
        issues

      Enum.any?(values, &(not is_binary(&1))) ->
        issues

      Enum.sort(values) == Enum.sort(expected) ->
        issues

      true ->
        [error(callbacks, path, message) | issues]
    end
  end

  defp validate_row_type(issues, callbacks, path, row) do
    case Map.get(row, "type") do
      type when is_binary(type) ->
        issues

      types when is_list(types) ->
        if Enum.all?(types, &is_binary/1) do
          issues
        else
          [error(callbacks, "#{path}.type", "must be a string or list of strings") | issues]
        end

      _type ->
        [error(callbacks, "#{path}.type", "must be a string or list of strings") | issues]
    end
  end

  defp validate_parent_path(issues, callbacks, path, row, path_set) do
    case {Map.get(row, "path"), Map.get(row, "parent_path")} do
      {row_path, "$"} when is_binary(row_path) ->
        issues

      {_row_path, parent_path} when is_binary(parent_path) ->
        if MapSet.member?(path_set, parent_path) do
          issues
        else
          [
            error(callbacks, "#{path}.parent_path", "must reference another field path or $")
            | issues
          ]
        end

      _values ->
        issues
    end
  end

  defp validate_section(issues, callbacks, path, row) do
    case {Map.get(row, "path"), Map.get(row, "section")} do
      {row_path, section} when is_binary(row_path) and is_binary(section) ->
        expected_section =
          row_path
          |> String.trim_leading("$.")
          |> String.split(".", parts: 2)
          |> List.first()

        if section == expected_section do
          issues
        else
          [error(callbacks, "#{path}.section", "must match the top-level field section") | issues]
        end

      _values ->
        issues
    end
  end

  defp validate_array_item(issues, callbacks, path, row) do
    case {Map.get(row, "path"), Map.get(row, "array_item")} do
      {row_path, array_item?} when is_binary(row_path) and is_boolean(array_item?) ->
        if array_item? == String.ends_with?(row_path, ".[]") do
          issues
        else
          [
            error(callbacks, "#{path}.array_item", "must match whether path ends with .[]")
            | issues
          ]
        end

      _values ->
        issues
    end
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
