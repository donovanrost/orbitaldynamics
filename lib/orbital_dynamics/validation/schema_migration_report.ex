defmodule OrbitalDynamics.Validation.SchemaMigrationReport do
  @moduledoc false

  def build(opts, context) when is_list(opts) and is_map(context) do
    contracts = Keyword.get(opts, :contracts, context.contracts.())

    deprecated_contracts =
      normalize_deprecated_contracts(Keyword.get(opts, :deprecated_contracts, %{}))

    future_contracts = normalize_future_contracts(Keyword.get(opts, :future_contracts, []))

    rows =
      contracts
      |> Enum.map(fn {schema_contract, contract} ->
        schema_migration_contract_row(
          schema_contract,
          stringify_keys(contract),
          Map.get(deprecated_contracts, schema_contract)
        )
      end)
      |> Kernel.++(future_contracts)
      |> Enum.sort_by(&{&1["schema_contract"], &1["status"]})

    status_counts = count_rows_by_value(rows, "status")
    migration_action_counts = count_rows_by_value(rows, "migration_action")
    compatibility_policy = context.compatibility_policy.()

    %{
      "schema_contract" => context.schema_contract,
      "schema_version" => 1,
      "model" => "executable_schema_migration_and_deprecation_report",
      "source" => "orbital_dynamics.schema_registry",
      "status" => schema_migration_status(status_counts),
      "compatibility_policy_version" => compatibility_policy["policy_version"],
      "compatible_change_rule_count" => length(compatibility_policy["compatible_changes"] || []),
      "breaking_change_rule_count" => length(compatibility_policy["breaking_changes"] || []),
      "contract_count" => length(rows),
      "current_contract_count" => Map.get(status_counts, "current", 0),
      "deprecated_contract_count" => Map.get(status_counts, "deprecated", 0),
      "future_contract_count" => Map.get(status_counts, "future", 0),
      "migration_row_count" => length(rows),
      "deprecation_warning_count" => Map.get(status_counts, "deprecated", 0),
      "status_counts" => status_counts,
      "migration_action_counts" => migration_action_counts,
      "rows" => rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "deprecation_source" => "caller_declared_deprecation_hints"
      },
      "model_limits" => schema_migration_model_limits()
    }
  end

  defp schema_migration_contract_row(schema_contract, contract, replacement_contract) do
    status = if is_binary(replacement_contract), do: "deprecated", else: "current"

    %{
      "schema_contract" => schema_contract,
      "artifact_family" => Map.get(contract, "artifact_family"),
      "schema_version" => Map.get(contract, "schema_version"),
      "status" => status,
      "migration_action" => schema_migration_action(status, replacement_contract),
      "replacement_contract" => replacement_contract,
      "required_field_count" => count(contract, "required_fields"),
      "optional_field_count" => count(contract, "optional_fields"),
      "nested_contract_count" => count(contract, "nested_contracts"),
      "deprecation_warning" => schema_migration_warning(schema_contract, replacement_contract)
    }
    |> compact_validation_map()
  end

  defp normalize_deprecated_contracts(deprecated_contracts) when is_map(deprecated_contracts) do
    deprecated_contracts
    |> Enum.map(fn {contract, replacement} ->
      {to_string(contract), normalize_optional_string(replacement)}
    end)
    |> Map.new()
  end

  defp normalize_deprecated_contracts(deprecated_contracts) when is_list(deprecated_contracts) do
    deprecated_contracts
    |> Enum.map(fn
      {contract, replacement} -> {to_string(contract), normalize_optional_string(replacement)}
      contract -> {to_string(contract), nil}
    end)
    |> Map.new()
  end

  defp normalize_deprecated_contracts(_deprecated_contracts), do: %{}

  defp normalize_future_contracts(future_contracts) when is_list(future_contracts) do
    future_contracts
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(fn row ->
      %{
        "schema_contract" => Map.get(row, "schema_contract"),
        "artifact_family" => Map.get(row, "artifact_family"),
        "schema_version" => Map.get(row, "schema_version"),
        "status" => "future",
        "migration_action" => "prepare_future_contract",
        "replacement_contract" => Map.get(row, "replacement_contract"),
        "required_field_count" =>
          integer_observation_value(Map.get(row, "required_field_count")) || 0,
        "optional_field_count" =>
          integer_observation_value(Map.get(row, "optional_field_count")) || 0,
        "nested_contract_count" =>
          integer_observation_value(Map.get(row, "nested_contract_count")) || 0,
        "deprecation_warning" => Map.get(row, "deprecation_warning")
      }
      |> compact_validation_map()
    end)
  end

  defp normalize_future_contracts(_future_contracts), do: []

  defp schema_migration_action("deprecated", replacement_contract)
       when is_binary(replacement_contract),
       do: "plan_replacement"

  defp schema_migration_action("deprecated", _replacement_contract),
    do: "review_deprecated_contract"

  defp schema_migration_action("current", _replacement_contract), do: "continue_current_contract"

  defp schema_migration_warning(_schema_contract, nil), do: nil

  defp schema_migration_warning(schema_contract, replacement_contract) do
    "#{schema_contract} is deprecated for compatibility routing; plan migration to #{replacement_contract}"
  end

  defp schema_migration_status(%{} = status_counts) do
    if Map.get(status_counts, "deprecated", 0) > 0 or Map.get(status_counts, "future", 0) > 0,
      do: "review_required",
      else: "current"
  end

  defp schema_migration_model_limits do
    [
      "artifact_only_schema_registry_snapshot",
      "deprecation_hints_are_caller_declared",
      "no_automatic_artifact_migration",
      "no_backward_compatibility_certification"
    ]
  end

  defp normalize_optional_string(value) when value in [nil, ""], do: nil
  defp normalize_optional_string(value), do: to_string(value)

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp integer_observation_value(value) when is_integer(value), do: value
  defp integer_observation_value(value) when is_float(value), do: trunc(value)

  defp integer_observation_value(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} -> integer
      _parse_error -> nil
    end
  end

  defp integer_observation_value(_value), do: nil

  defp compact_validation_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
