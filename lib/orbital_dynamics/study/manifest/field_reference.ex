defmodule OrbitalDynamics.Study.Manifest.FieldReference do
  @moduledoc false

  def build(schema, metadata) do
    fields = schema_field_rows(schema, metadata.identity_policy["stable_id_pattern"])

    %{
      "schema_contract" => metadata.schema_contract,
      "schema_version" => metadata.schema_version,
      "reference_mode" => "study_manifest_schema_field_reference",
      "compatibility_policy_version" => metadata.compatibility_policy["policy_version"],
      "identity_policy_version" => metadata.identity_policy["policy_version"],
      "identity_policy" =>
        Map.take(metadata.identity_policy, [
          "policy_version",
          "stable_id_pattern",
          "semantic_invariants",
          "generated_id_scopes"
        ]),
      "schema_export_command" =>
        "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
      "lint_command" => "mix orbital_dynamics.manifest.lint --manifest PATH",
      "field_count" => length(fields),
      "top_level_required" => Map.get(schema, "required", []),
      "activation_sections" =>
        schema
        |> Map.get("anyOf", [])
        |> Enum.flat_map(&Map.get(&1, "required", [])),
      "supported" => metadata.supported,
      "fields" => fields
    }
  end

  defp schema_field_rows(schema, stable_id_pattern) do
    schema
    |> Map.get("properties", %{})
    |> Enum.sort_by(fn {field, _property} -> field end)
    |> Enum.flat_map(fn {field, property} ->
      field_rows(
        ["$", field],
        property,
        MapSet.new(Map.get(schema, "required", [])),
        stable_id_pattern
      )
    end)
  end

  defp field_rows(path, property, required_fields, stable_id_pattern) do
    field = List.last(path)
    child_required_fields = MapSet.new(Map.get(property, "required", []))
    row = field_row(path, property, MapSet.member?(required_fields, field), stable_id_pattern)

    child_rows =
      property
      |> Map.get("properties", %{})
      |> Enum.sort_by(fn {child_field, _child_property} -> child_field end)
      |> Enum.flat_map(fn {child_field, child_property} ->
        field_rows(
          path ++ [child_field],
          child_property,
          child_required_fields,
          stable_id_pattern
        )
      end)

    item_rows =
      case Map.get(property, "items") do
        %{} = item_schema ->
          field_rows(path ++ ["[]"], item_schema, MapSet.new(), stable_id_pattern)

        _items ->
          []
      end

    [row | child_rows ++ item_rows]
  end

  defp field_row(path, property, required?, stable_id_pattern) do
    %{
      "path" => Enum.join(path, "."),
      "parent_path" => parent_path(path),
      "section" => manifest_section(path),
      "type" => schema_type(property),
      "required" => required?,
      "array_item" => List.last(path) == "[]"
    }
    |> maybe_put("enum", Map.get(property, "enum"))
    |> maybe_put("const", Map.get(property, "const"))
    |> maybe_put("description", Map.get(property, "description"))
    |> maybe_put("min_items", Map.get(property, "minItems"))
    |> maybe_put("max_items", Map.get(property, "maxItems"))
    |> maybe_put("minimum", Map.get(property, "minimum"))
    |> maybe_put("maximum", Map.get(property, "maximum"))
    |> maybe_put("schema_contract_ref", schema_contract_ref(property))
    |> maybe_put("additional_properties_type", additional_properties_type(property))
    |> maybe_put("stable_id_pattern", stable_id_pattern(path, property, stable_id_pattern))
    |> maybe_put_non_empty("trust_boundary_sources", trust_boundary_sources(property))
    |> maybe_put_non_empty("nested_contracts", nested_contracts(property))
    |> maybe_put_non_empty("required_children", Map.get(property, "required", []))
    |> maybe_put_non_empty("required_alternatives", required_alternatives(property))
  end

  defp parent_path(["$", _field]), do: "$"

  defp parent_path(path) do
    path
    |> Enum.drop(-1)
    |> Enum.join(".")
  end

  defp manifest_section(["$", section | _rest]), do: section
  defp manifest_section(_path), do: "$"

  defp schema_type(%{"type" => type}), do: type
  defp schema_type(%{"oneOf" => _one_of}), do: "oneOf"
  defp schema_type(%{"anyOf" => _any_of}), do: "anyOf"
  defp schema_type(%{"allOf" => _all_of}), do: "allOf"
  defp schema_type(_property), do: "unspecified"

  defp required_alternatives(%{"anyOf" => alternatives, "allOf" => all_of})
       when is_list(alternatives) and is_list(all_of) do
    required_alternatives_from_any_of(alternatives) ++ required_alternatives_from_all_of(all_of)
  end

  defp required_alternatives(%{"anyOf" => alternatives}) when is_list(alternatives) do
    required_alternatives_from_any_of(alternatives)
  end

  defp required_alternatives(%{"allOf" => all_of}) when is_list(all_of) do
    required_alternatives_from_all_of(all_of)
  end

  defp required_alternatives(_property), do: []

  defp required_alternatives_from_all_of(all_of) do
    Enum.flat_map(all_of, fn
      %{"anyOf" => alternatives} when is_list(alternatives) ->
        required_alternatives_from_any_of(alternatives)

      _schema ->
        []
    end)
  end

  defp required_alternatives_from_any_of(alternatives) do
    alternatives
    |> Enum.flat_map(fn
      %{"required" => required} when is_list(required) -> [required]
      _alternative -> []
    end)
  end

  defp schema_contract_ref(%{"x-orbital-dynamics" => %{"schema_contract" => contract}})
       when is_binary(contract),
       do: contract

  defp schema_contract_ref(%{"properties" => %{"schema_contract" => %{"const" => contract}}})
       when is_binary(contract),
       do: contract

  defp schema_contract_ref(_property), do: nil

  defp nested_contracts(%{"x-orbital-dynamics" => %{"nested_contracts" => contracts}})
       when is_list(contracts),
       do: Enum.filter(contracts, &is_binary/1)

  defp nested_contracts(_property), do: []

  defp additional_properties_type(%{"additionalProperties" => %{} = property}) do
    schema_type(property)
  end

  defp additional_properties_type(_property), do: nil

  defp stable_id_pattern(path, property, stable_id_pattern) do
    if stable_id_field_path?(path, property), do: stable_id_pattern
  end

  defp stable_id_field_path?(path, %{"type" => "string"}) do
    if List.last(path) == "[]" do
      path
      |> Enum.at(-2)
      |> stable_id_array_field_name?()
    else
      path
      |> List.last()
      |> stable_id_field_name?()
    end
  end

  defp stable_id_field_path?(path, %{"type" => "array", "items" => %{"type" => "string"}}) do
    path
    |> List.last()
    |> stable_id_array_field_name?()
  end

  defp stable_id_field_path?(_path, _property), do: false

  defp stable_id_field_name?("id"), do: true
  defp stable_id_field_name?("study_id"), do: true
  defp stable_id_field_name?("snapshot_id"), do: true
  defp stable_id_field_name?("activity_id"), do: true
  defp stable_id_field_name?("spacecraft_id"), do: true
  defp stable_id_field_name?("scenario_id"), do: true
  defp stable_id_field_name?("station_id"), do: true
  defp stable_id_field_name?("ground_station_id"), do: true
  defp stable_id_field_name?("target_id"), do: true
  defp stable_id_field_name?("source_window_id"), do: true
  defp stable_id_field_name?("reservation_id"), do: true
  defp stable_id_field_name?(field) when is_binary(field), do: String.ends_with?(field, "_id")
  defp stable_id_field_name?(_field), do: false

  defp stable_id_array_field_name?("dependencies"), do: true

  defp stable_id_array_field_name?(field) when is_binary(field),
    do: String.ends_with?(field, "_ids")

  defp stable_id_array_field_name?(_field), do: false

  defp trust_boundary_sources(property) do
    alternatives = required_alternatives(property)
    required = Map.get(property, "required", [])

    cond do
      ["trust_boundary"] in alternatives and ["provenance"] in alternatives ->
        ["trust_boundary", "provenance.trust_boundary"]

      "trust_boundary" in required ->
        ["trust_boundary"]

      true ->
        []
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_non_empty(map, _key, []), do: map
  defp maybe_put_non_empty(map, key, value), do: maybe_put(map, key, value)
end
