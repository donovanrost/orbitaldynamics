defmodule OrbitalDynamics.Schema.ManifestFieldReferenceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 5,
      expect_non_negative_integer: 4,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  def validate(issues, path, artifact) do
    issues
    |> expect_equal(
      path,
      artifact,
      "reference_mode",
      "study_manifest_schema_field_reference"
    )
    |> expect_equal(path, artifact, "schema_version", 1)
    |> expect_non_negative_integer(path, artifact, "field_count")
    |> expect_type(path, artifact, "fields", :list)
    |> expect_type(path, artifact, "top_level_required", :list)
    |> expect_type(path, artifact, "activation_sections", :list)
    |> expect_type(path, artifact, "supported", :map)
    |> expect_type(
      path <> ".supported",
      Map.get(artifact, "supported", %{}),
      "lint_error_codes",
      :list
    )
    |> validate_string_list_items(
      path <> ".supported",
      Map.get(artifact, "supported", %{}),
      "lint_error_codes"
    )
    |> validate_rows(path, artifact)
  end

  defp validate_rows(issues, path, artifact) do
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
        |> expect_field_equals(path, artifact, "field_count", length(fields))
        |> validate_duplicate_paths(path, row_paths)
        |> validate_top_level_required(path, artifact, rows_by_path)
        |> validate_activation_sections(path, artifact, rows_by_path)
        |> validate_supported_vocabularies(path, artifact, rows_by_path)
        |> validate_row_integrity(path, fields, path_set)

      _fields ->
        issues
    end
  end

  defp validate_row_integrity(issues, path, fields, path_set) do
    fields
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc ->
        row_path = "#{path}.fields[#{index}]"

        acc
        |> require_fields(row_path, row, [
          "path",
          "parent_path",
          "section",
          "type",
          "required",
          "array_item"
        ])
        |> expect_type(row_path, row, "path", :binary)
        |> expect_type(row_path, row, "parent_path", :binary)
        |> expect_type(row_path, row, "section", :binary)
        |> validate_row_type(row_path, row)
        |> expect_type(row_path, row, "required", :boolean)
        |> expect_type(row_path, row, "array_item", :boolean)
        |> validate_parent_path(row_path, row, path_set)
        |> validate_section(row_path, row)
        |> validate_array_item(row_path, row)

      {_row, index}, acc ->
        [error("#{path}.fields[#{index}]", "must be an object") | acc]
    end)
  end

  defp validate_duplicate_paths(issues, path, row_paths) do
    row_paths
    |> Enum.frequencies()
    |> Enum.filter(fn {_row_path, count} -> count > 1 end)
    |> Enum.reduce(issues, fn {duplicate_path, _count}, acc ->
      [
        error(
          "#{path}.fields",
          "contains duplicate field path #{inspect(duplicate_path)}"
        )
        | acc
      ]
    end)
  end

  defp validate_top_level_required(issues, path, artifact, rows_by_path) do
    case Map.get(artifact, "top_level_required") do
      fields when is_list(fields) ->
        issues
        |> validate_top_level_required_fields(path, fields, rows_by_path)
        |> expect_string_list_set_equals(
          path <> ".top_level_required",
          fields,
          top_level_required(rows_by_path),
          "must equal row-derived top-level required fields"
        )

      _fields ->
        issues
    end
  end

  defp validate_top_level_required_fields(issues, path, fields, rows_by_path) do
    fields
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {field, index}, acc when is_binary(field) ->
        validate_top_level_required_field(acc, path, index, field, rows_by_path)

      {_field, index}, acc ->
        [error("#{path}.top_level_required[#{index}]", "must be a string") | acc]
    end)
  end

  defp top_level_required(rows_by_path) do
    rows_by_path
    |> Map.values()
    |> Enum.filter(&(Map.get(&1, "parent_path") == "$" and Map.get(&1, "required") == true))
    |> Enum.map(&(&1 |> Map.fetch!("path") |> String.trim_leading("$.")))
    |> Enum.sort()
  end

  defp validate_top_level_required_field(issues, path, index, field, rows_by_path) do
    row = Map.get(rows_by_path, "$.#{field}")

    cond do
      not is_map(row) ->
        [
          error(
            "#{path}.top_level_required[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "parent_path") != "$" ->
        [
          error(
            "#{path}.top_level_required[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "required") != true ->
        [
          error(
            "#{path}.top_level_required[#{index}]",
            "must reference a required field row"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_activation_sections(issues, path, artifact, rows_by_path) do
    case Map.get(artifact, "activation_sections") do
      sections when is_list(sections) ->
        validate_activation_section_entries(issues, path, sections, rows_by_path)

      _sections ->
        issues
    end
  end

  defp validate_activation_section_entries(issues, path, sections, rows_by_path) do
    sections
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {section, index}, acc when is_binary(section) ->
        validate_activation_section(acc, path, index, section, rows_by_path)

      {_section, index}, acc ->
        [error("#{path}.activation_sections[#{index}]", "must be a string") | acc]
    end)
  end

  defp validate_activation_section(issues, path, index, section, rows_by_path) do
    row = Map.get(rows_by_path, "$.#{section}")

    cond do
      not is_map(row) ->
        [
          error(
            "#{path}.activation_sections[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "parent_path") != "$" ->
        [
          error(
            "#{path}.activation_sections[#{index}]",
            "must reference a top-level field"
          )
          | issues
        ]

      Map.get(row, "section") != section ->
        [
          error(
            "#{path}.activation_sections[#{index}]",
            "must match the activated field section"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_supported_vocabularies(issues, path, artifact, rows_by_path) do
    supported = Map.get(artifact, "supported", %{})

    issues
    |> validate_supported_enum(
      "#{path}.supported",
      supported,
      "outputs",
      Map.get(rows_by_path, "$.outputs.[]")
    )
    |> validate_supported_enum(
      "#{path}.supported",
      supported,
      "propagators",
      Map.get(rows_by_path, "$.propagator")
    )
    |> validate_supported_enum(
      "#{path}.supported",
      supported,
      "search_objectives",
      Map.get(rows_by_path, "$.search.objective")
    )
    |> validate_supported_enum(
      "#{path}.supported",
      supported,
      "search_objectives",
      Map.get(rows_by_path, "$.monte_carlo.objective")
    )
  end

  defp validate_supported_enum(issues, path, supported, field, row)
       when is_map(supported) and is_map(row) do
    case {Map.get(supported, field), Map.get(row, "enum")} do
      {values, enum_values} when is_list(values) and is_list(enum_values) ->
        cond do
          not Enum.all?(values, &is_binary/1) ->
            [error("#{path}.#{field}", "must be a list of strings") | issues]

          Enum.sort(values) == Enum.sort(enum_values) ->
            issues

          true ->
            [
              error("#{path}.#{field}", "must match manifest schema enum values")
              | issues
            ]
        end

      {values, _enum_values} when is_list(values) ->
        [
          error("#{path}.#{field}", "must have matching manifest field enum evidence")
          | issues
        ]

      {_values, _enum_values} ->
        [error("#{path}.#{field}", "must be a list") | issues]
    end
  end

  defp validate_supported_enum(issues, path, supported, field, _row)
       when is_map(supported) do
    [
      error("#{path}.#{field}", "must have matching manifest field enum evidence")
      | issues
    ]
  end

  defp validate_supported_enum(issues, _path, _supported, _field, _row), do: issues

  defp expect_string_list_set_equals(issues, path, values, expected, message) do
    cond do
      not is_list(values) ->
        issues

      Enum.any?(values, &(not is_binary(&1))) ->
        issues

      Enum.sort(values) == Enum.sort(expected) ->
        issues

      true ->
        [error(path, message) | issues]
    end
  end

  defp validate_row_type(issues, path, row) do
    case Map.get(row, "type") do
      type when is_binary(type) ->
        issues

      types when is_list(types) ->
        if Enum.all?(types, &is_binary/1) do
          issues
        else
          [error("#{path}.type", "must be a string or list of strings") | issues]
        end

      _type ->
        [error("#{path}.type", "must be a string or list of strings") | issues]
    end
  end

  defp validate_parent_path(issues, path, row, path_set) do
    case {Map.get(row, "path"), Map.get(row, "parent_path")} do
      {row_path, "$"} when is_binary(row_path) ->
        issues

      {_row_path, parent_path} when is_binary(parent_path) ->
        if MapSet.member?(path_set, parent_path) do
          issues
        else
          [
            error("#{path}.parent_path", "must reference another field path or $")
            | issues
          ]
        end

      _values ->
        issues
    end
  end

  defp validate_section(issues, path, row) do
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
          [error("#{path}.section", "must match the top-level field section") | issues]
        end

      _values ->
        issues
    end
  end

  defp validate_array_item(issues, path, row) do
    case {Map.get(row, "path"), Map.get(row, "array_item")} do
      {row_path, array_item?} when is_binary(row_path) and is_boolean(array_item?) ->
        if array_item? == String.ends_with?(row_path, ".[]") do
          issues
        else
          [
            error("#{path}.array_item", "must match whether path ends with .[]")
            | issues
          ]
        end

      _values ->
        issues
    end
  end
end
