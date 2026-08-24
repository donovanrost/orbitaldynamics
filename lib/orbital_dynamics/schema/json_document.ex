defmodule OrbitalDynamics.Schema.JsonDocument do
  @moduledoc false

  @closed_top_level_contracts ["candidate_refresh_execution.v1"]

  def options(attrs) do
    [
      json_schema_draft: Keyword.fetch!(attrs, :json_schema_draft),
      compatibility_policy: Keyword.fetch!(attrs, :compatibility_policy),
      identity_policy: Keyword.fetch!(attrs, :identity_policy),
      contract_fun: Keyword.fetch!(attrs, :contract_fun),
      property_fun: Keyword.fetch!(attrs, :property_fun),
      stable_id_pattern: Keyword.fetch!(attrs, :stable_id_pattern),
      constraint_report_model_limits_by_model_fun:
        Keyword.fetch!(attrs, :constraint_report_model_limits_by_model_fun),
      validation_record_registry_conditions_fun:
        Keyword.fetch!(attrs, :validation_record_registry_conditions_fun),
      contract_names: contract_names(attrs)
    ]
  end

  def build_from_attrs(name, contract, attrs) do
    build(name, contract, options(attrs))
  end

  def candidate_activity(schema, contract_name, opts)
      when is_map(schema) and is_binary(contract_name) do
    schema
    |> Map.put("$schema", Keyword.fetch!(opts, :json_schema_draft))
    |> Map.put("$id", "https://orbital-dynamics.local/schemas/#{contract_name}.schema.json")
    |> Map.put("title", "OrbitalDynamics #{contract_name}")
    |> Map.put("x-orbital-dynamics", %{
      "schema_contract" => contract_name,
      "artifact_family" => "candidate_activity",
      "schema_version" => 1,
      "nested_contracts" => [],
      "validation_mode" => "top_level_compatibility_export",
      "nested_contract_definition_scope" => "direct_declared_contracts",
      "compatibility_policy" => Keyword.fetch!(opts, :compatibility_policy),
      "identity_policy" => Keyword.fetch!(opts, :identity_policy),
      "compatibility_policy_version" =>
        Keyword.fetch!(opts, :compatibility_policy)["policy_version"],
      "identity_policy_version" => Keyword.fetch!(opts, :identity_policy)["policy_version"],
      "executable_contract" => true
    })
  end

  def build(name, contract, opts) do
    required_fields = contract["required_fields"]
    optional_fields = Map.get(contract, "optional_fields", [])
    property_fields = Enum.uniq(required_fields ++ optional_fields)
    nested_defs = nested_schema_definitions(contract["nested_contracts"], opts)

    %{
      "$schema" => Keyword.fetch!(opts, :json_schema_draft),
      "$id" => "https://orbital-dynamics.local/schemas/#{name}.schema.json",
      "title" => "OrbitalDynamics #{name}",
      "type" => "object",
      "additionalProperties" => additional_properties?(name, contract),
      "required" => required_fields,
      "properties" =>
        property_fields
        |> Enum.sort()
        |> Map.new(&{&1, property_schema(&1, name, contract, opts)}),
      "x-orbital-dynamics" => %{
        "schema_contract" => name,
        "artifact_family" => contract["artifact_family"],
        "schema_version" => contract["schema_version"],
        "nested_contracts" => contract["nested_contracts"],
        "validation_mode" => "top_level_compatibility_export",
        "nested_contract_definition_scope" => "direct_declared_contracts",
        "compatibility_policy" => Keyword.fetch!(opts, :compatibility_policy),
        "identity_policy" => Keyword.fetch!(opts, :identity_policy),
        "compatibility_policy_version" =>
          Keyword.fetch!(opts, :compatibility_policy)["policy_version"],
        "identity_policy_version" => Keyword.fetch!(opts, :identity_policy)["policy_version"],
        "executable_contract" => true
      }
    }
    |> maybe_put_non_empty("$defs", nested_defs)
    |> maybe_add_trust_boundary_requirement(name, opts)
    |> maybe_add_accepted_planning_state_import_requirement(name, opts)
    |> maybe_add_realized_activity_provider_requirement(name, opts)
    |> maybe_add_planned_activity_type_requirement(name, opts)
    |> maybe_add_constraint_report_model_limit_conditions(name, opts)
    |> maybe_add_environment_model_capability_known_limit_conditions(name, opts)
    |> maybe_add_environment_provider_capability_known_limit_conditions(name, opts)
    |> maybe_add_subsystem_model_capability_known_limit_conditions(name, opts)
    |> maybe_add_validation_record_registry_conditions(name, opts)
  end

  defp property_schema(field, name, contract, opts) do
    opts
    |> Keyword.fetch!(:property_fun)
    |> then(& &1.(field, name, contract))
  end

  defp additional_properties?(name, contract) do
    Map.get(contract, "additional_properties", name not in @closed_top_level_contracts)
  end

  defp maybe_put_non_empty(map, _key, value) when value == %{}, do: map
  defp maybe_put_non_empty(map, key, value), do: Map.put(map, key, value)

  defp maybe_add_planned_activity_type_requirement(schema, name, opts) do
    if name == contract_name(opts, :planned_activity) do
      Map.put(schema, "anyOf", [
        %{"required" => ["type"]},
        %{"required" => ["activity_type"]}
      ])
    else
      schema
    end
  end

  defp maybe_add_trust_boundary_requirement(schema, name, opts) do
    if name in [
         contract_name(opts, :station_calendar_provider),
         contract_name(opts, :spacecraft_state_estimate),
         contract_name(opts, :maneuver_execution_delta)
       ] do
      Map.put(schema, "anyOf", [
        %{"required" => ["trust_boundary"]},
        %{
          "required" => ["provenance"],
          "properties" => %{
            "provenance" => %{
              "type" => "object",
              "required" => ["trust_boundary"],
              "properties" => %{"trust_boundary" => %{"type" => "string"}},
              "additionalProperties" => true
            }
          }
        }
      ])
    else
      schema
    end
  end

  defp maybe_add_accepted_planning_state_import_requirement(schema, name, opts) do
    if name == contract_name(opts, :accepted_planning_state) do
      Map.put(schema, "allOf", [
        %{
          "if" => %{
            "properties" => %{
              "provenance" => %{
                "type" => "object",
                "anyOf" => [
                  %{"required" => ["input_format"]},
                  %{"required" => ["import_adapter"]},
                  %{"required" => ["provider"]},
                  %{"required" => ["adapter"]},
                  %{"required" => ["adapter_version"]}
                ]
              }
            }
          },
          "then" => %{
            "properties" => %{
              "provenance" => %{
                "type" => "object",
                "required" => ["trust_boundary"],
                "properties" => %{"trust_boundary" => %{"type" => "string"}},
                "additionalProperties" => true
              }
            }
          }
        }
      ])
    else
      schema
    end
  end

  defp maybe_add_realized_activity_provider_requirement(schema, name, opts) do
    if name == contract_name(opts, :realized_activity) do
      Map.put(schema, "allOf", [
        %{
          "if" => %{
            "anyOf" => [
              %{"required" => ["provider"]},
              %{"required" => ["adapter"]},
              %{"required" => ["adapter_version"]},
              %{"required" => ["external_id"]}
            ]
          },
          "then" => %{
            "required" => ["external_id"],
            "anyOf" => [
              %{"required" => ["trust_boundary"]},
              %{
                "required" => ["provenance"],
                "properties" => %{
                  "provenance" => %{
                    "type" => "object",
                    "required" => ["trust_boundary"],
                    "properties" => %{"trust_boundary" => %{"type" => "string"}},
                    "additionalProperties" => true
                  }
                }
              }
            ]
          }
        }
      ])
    else
      schema
    end
  end

  defp maybe_add_constraint_report_model_limit_conditions(schema, name, opts) do
    if name == contract_name(opts, :constraint_report) do
      conditions =
        opts
        |> Keyword.fetch!(:constraint_report_model_limits_by_model_fun)
        |> then(& &1.())
        |> Enum.map(fn {model, limits} ->
          %{
            "if" => %{"properties" => %{"model" => %{"const" => model}}},
            "then" => %{"properties" => %{"model_limits" => %{"const" => limits}}}
          }
        end)

      Map.update(schema, "allOf", conditions, &(List.wrap(&1) ++ conditions))
    else
      schema
    end
  end

  defp maybe_add_environment_model_capability_known_limit_conditions(schema, name, opts) do
    if name == contract_name(opts, :environment_model_capability) do
      conditions =
        for %{"id" => id, "known_limits" => limits} <-
              OrbitalDynamics.Environment.model_capabilities() do
          %{
            "if" => %{"properties" => %{"id" => stable_id_const_json_schema(id, opts)}},
            "then" => %{"properties" => %{"known_limits" => %{"const" => limits}}}
          }
        end

      Map.update(schema, "allOf", conditions, &(List.wrap(&1) ++ conditions))
    else
      schema
    end
  end

  defp maybe_add_environment_provider_capability_known_limit_conditions(schema, name, opts) do
    if name == contract_name(opts, :environment_provider_capability) do
      conditions =
        for %{"id" => id, "known_limits" => limits} <-
              OrbitalDynamics.Environment.provider_capabilities() do
          %{
            "if" => %{"properties" => %{"id" => stable_id_const_json_schema(id, opts)}},
            "then" => %{"properties" => %{"known_limits" => %{"const" => limits}}}
          }
        end

      Map.update(schema, "allOf", conditions, &(List.wrap(&1) ++ conditions))
    else
      schema
    end
  end

  defp maybe_add_subsystem_model_capability_known_limit_conditions(schema, name, opts) do
    if name == contract_name(opts, :subsystem_model_capability) do
      conditions =
        for %{"id" => id, "known_limits" => limits} <-
              OrbitalDynamics.SubsystemModel.capabilities() do
          %{
            "if" => %{"properties" => %{"id" => stable_id_const_json_schema(id, opts)}},
            "then" => %{"properties" => %{"known_limits" => %{"const" => limits}}}
          }
        end

      Map.update(schema, "allOf", conditions, &(List.wrap(&1) ++ conditions))
    else
      schema
    end
  end

  defp maybe_add_validation_record_registry_conditions(schema, name, opts) do
    if name == contract_name(opts, :validation_record) do
      conditions =
        opts
        |> Keyword.fetch!(:validation_record_registry_conditions_fun)
        |> then(& &1.())

      Map.update(schema, "allOf", conditions, &(List.wrap(&1) ++ conditions))
    else
      schema
    end
  end

  defp nested_schema_definitions(contracts, opts) do
    contracts
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.flat_map(fn name ->
      case contract(name, opts) do
        {:ok, contract} ->
          [
            {name,
             name
             |> build(contract, opts)
             |> Map.delete("$defs")
             |> scrub_nested_schema_metadata()}
          ]

        :error ->
          []
      end
    end)
    |> Map.new()
  end

  defp scrub_nested_schema_metadata(schema) do
    update_in(schema, ["x-orbital-dynamics"], fn
      nil ->
        nil

      metadata ->
        metadata
        |> Map.delete("compatibility_policy")
        |> Map.delete("identity_policy")
    end)
  end

  defp contract(name, opts) do
    opts
    |> Keyword.fetch!(:contract_fun)
    |> then(& &1.(name))
  end

  defp contract_name(opts, key) do
    opts
    |> Keyword.fetch!(:contract_names)
    |> Map.fetch!(key)
  end

  defp contract_names(attrs) do
    %{
      accepted_planning_state: Keyword.fetch!(attrs, :accepted_planning_state),
      constraint_report: Keyword.fetch!(attrs, :constraint_report),
      environment_model_capability: Keyword.fetch!(attrs, :environment_model_capability),
      environment_provider_capability: Keyword.fetch!(attrs, :environment_provider_capability),
      maneuver_execution_delta: Keyword.fetch!(attrs, :maneuver_execution_delta),
      planned_activity: Keyword.fetch!(attrs, :planned_activity),
      realized_activity: Keyword.fetch!(attrs, :realized_activity),
      spacecraft_state_estimate: Keyword.fetch!(attrs, :spacecraft_state_estimate),
      station_calendar_provider: Keyword.fetch!(attrs, :station_calendar_provider),
      subsystem_model_capability: Keyword.fetch!(attrs, :subsystem_model_capability),
      validation_record: Keyword.fetch!(attrs, :validation_record)
    }
  end

  defp stable_id_const_json_schema(id, opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern), "const" => id}
  end
end
