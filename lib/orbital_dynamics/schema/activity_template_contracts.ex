defmodule OrbitalDynamics.Schema.ActivityTemplateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_id: 3]

  alias OrbitalDynamics.Schema.CollectionAggregation

  def validate(issues, path, template, contract, capabilities) when is_map(capabilities) do
    issues
    |> require_fields(path, template, contract["required_fields"])
    |> expect_equal(path, template, "schema_contract", "activity_template.v1")
    |> validate_stable_id(path <> ".id", Map.get(template, "id"))
    |> expect_one_of(path, template, "activity_type", capabilities.supported_activity_types)
    |> validate_version(path, template)
    |> expect_equal(path, template, "validation_level", "artifact_contract")
    |> expect_type(path, template, "known_limits", :list)
    |> validate_string_list_items(path, template, "known_limits")
    |> validate_metadata_fields(path, template)
    |> validate_field_lists(path, template)
    |> validate_default_fields(path, template)
    |> validate_lifecycle_defaults(path, template, capabilities)
    |> validate_operational_hints(path, template)
    |> validate_subsystem_state_hints(path, template)
    |> validate_resource_hints(path, template)
    |> validate_precondition_hints(path, template, capabilities)
  end

  defp validate_version(issues, path, template) do
    case Map.get(template, "template_version") do
      value when is_integer(value) and value >= 1 ->
        issues

      _value ->
        [
          error(
            "#{path}.template_version",
            "must be an integer greater than or equal to 1"
          )
          | issues
        ]
    end
  end

  defp validate_metadata_fields(issues, path, template) do
    issues
    |> validate_optional_type(path, template, "display_name", :binary)
    |> validate_optional_type(path, template, "description", :binary)
    |> validate_optional_type(path, template, "assumptions", :map)
  end

  defp validate_optional_type(issues, path, map, field, type) do
    if Map.has_key?(map, field) do
      expect_type(issues, path, map, field, type)
    else
      issues
    end
  end

  defp validate_optional_one_of(issues, path, map, field, allowed) do
    if Map.has_key?(map, field) do
      expect_one_of(issues, path, map, field, allowed)
    else
      issues
    end
  end

  defp validate_optional_number(issues, path, map, field) do
    case Map.fetch(map, field) do
      :error -> issues
      {:ok, value} when is_number(value) -> issues
      {:ok, _value} -> [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  defp validate_optional_non_negative_integer(issues, path, map, field) do
    case Map.fetch(map, field) do
      :error ->
        issues

      {:ok, value} when is_integer(value) and value >= 0 ->
        issues

      {:ok, _value} ->
        [error("#{path}.#{field}", "must be a non-negative integer") | issues]
    end
  end

  defp validate_optional_non_negative_number(issues, path, map, field) do
    case Map.fetch(map, field) do
      :error ->
        issues

      {:ok, value} when is_number(value) and value >= 0.0 ->
        issues

      {:ok, value} when is_number(value) ->
        [error("#{path}.#{field}", "must be non-negative") | issues]

      {:ok, _value} ->
        [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  defp validate_field_lists(issues, path, template) do
    issues
    |> validate_optional_type(path, template, "required_fields", :list)
    |> validate_string_list_items(path, template, "required_fields")
    |> validate_optional_type(path, template, "optional_fields", :list)
    |> validate_string_list_items(path, template, "optional_fields")
    |> validate_optional_non_negative_integer(path, template, "field_count")
    |> validate_optional_non_negative_integer(path, template, "required_field_count")
    |> validate_optional_non_negative_integer(path, template, "optional_field_count")
    |> expect_field_equals(
      path,
      template,
      "required_field_count",
      CollectionAggregation.list_count(template, "required_fields"),
      "must equal required_fields count"
    )
    |> expect_field_equals(
      path,
      template,
      "optional_field_count",
      CollectionAggregation.list_count(template, "optional_fields"),
      "must equal optional_fields count"
    )
    |> expect_field_equals(
      path,
      template,
      "field_count",
      declared_field_count(template),
      "must equal required_fields plus optional_fields count"
    )
  end

  defp declared_field_count(template) do
    required_count = CollectionAggregation.list_count(template, "required_fields")
    optional_count = CollectionAggregation.list_count(template, "optional_fields")

    if is_integer(required_count) and is_integer(optional_count) do
      required_count + optional_count
    end
  end

  defp validate_default_fields(issues, path, template) do
    case Map.fetch(template, "default_fields") do
      :error ->
        issues

      {:ok, defaults} when is_map(defaults) ->
        declared_fields = declared_fields(template)

        Enum.reduce(defaults, issues, fn {field, _value}, acc ->
          if field in declared_fields do
            acc
          else
            [
              error(
                "#{path}.default_fields.#{field}",
                "must be declared in required_fields or optional_fields"
              )
              | acc
            ]
          end
        end)

      {:ok, _value} ->
        [error("#{path}.default_fields", "must be a map") | issues]
    end
  end

  defp declared_fields(template) do
    template
    |> Map.take(["required_fields", "optional_fields"])
    |> Map.values()
    |> Enum.flat_map(fn
      values when is_list(values) -> Enum.filter(values, &is_binary/1)
      _value -> []
    end)
    |> MapSet.new()
  end

  defp validate_lifecycle_defaults(issues, path, template, capabilities) do
    case Map.fetch(template, "lifecycle_defaults") do
      :error ->
        issues

      {:ok, defaults} when is_map(defaults) ->
        issues
        |> validate_optional_one_of(
          "#{path}.lifecycle_defaults",
          defaults,
          "status",
          capabilities.activity_statuses
        )
        |> validate_optional_one_of(
          "#{path}.lifecycle_defaults",
          defaults,
          "approval_status",
          capabilities.approval_statuses
        )
        |> validate_optional_type(
          "#{path}.lifecycle_defaults",
          defaults,
          "locked",
          :boolean
        )
        |> validate_optional_type(
          "#{path}.lifecycle_defaults",
          defaults,
          "allow_overlap",
          :boolean
        )

      {:ok, _value} ->
        [error("#{path}.lifecycle_defaults", "must be a map") | issues]
    end
  end

  defp validate_operational_hints(issues, path, template) do
    case Map.fetch(template, "operational_hints") do
      :error ->
        issues

      {:ok, hints} when is_map(hints) ->
        issues
        |> validate_optional_non_negative_number(
          "#{path}.operational_hints",
          hints,
          "setup_duration_s"
        )
        |> validate_optional_non_negative_number(
          "#{path}.operational_hints",
          hints,
          "cooldown_duration_s"
        )
        |> validate_optional_type(
          "#{path}.operational_hints",
          hints,
          "telemetry_confirmation_required",
          :boolean
        )
        |> validate_optional_type(
          "#{path}.operational_hints",
          hints,
          "telemetry_confirmation_status",
          :binary
        )

      {:ok, _value} ->
        [error("#{path}.operational_hints", "must be a map") | issues]
    end
  end

  defp validate_resource_hints(issues, path, template) do
    case Map.fetch(template, "resource_hints") do
      :error ->
        issues

      {:ok, hints} when is_map(hints) ->
        boolean_fields = [
          "requires_payload",
          "requires_antenna",
          "requires_contact",
          "uses_storage",
          "uses_power",
          "uses_fuel"
        ]

        string_list_fields = ["suppressed_activity_types", "incompatible_activity_types"]

        non_negative_number_fields = [
          "estimated_data_volume_mb",
          "estimated_downlink_mb",
          "battery_energy_used_wh",
          "battery_energy_generated_wh"
        ]

        number_fields = [
          "fuel_margin",
          "power_margin",
          "storage_margin",
          "downlink_margin",
          "thermal_margin_c"
        ]

        issues =
          Enum.reduce(boolean_fields, issues, fn field, acc ->
            validate_optional_type(
              acc,
              "#{path}.resource_hints",
              hints,
              field,
              :boolean
            )
          end)

        issues =
          Enum.reduce(string_list_fields, issues, fn field, acc ->
            acc
            |> validate_optional_type("#{path}.resource_hints", hints, field, :list)
            |> validate_string_list_items("#{path}.resource_hints", hints, field)
          end)

        issues =
          Enum.reduce(non_negative_number_fields, issues, fn field, acc ->
            validate_optional_non_negative_number(
              acc,
              "#{path}.resource_hints",
              hints,
              field
            )
          end)

        Enum.reduce(number_fields, issues, fn field, acc ->
          validate_optional_number(acc, "#{path}.resource_hints", hints, field)
        end)

      {:ok, _value} ->
        [error("#{path}.resource_hints", "must be a map") | issues]
    end
  end

  defp validate_subsystem_state_hints(issues, path, template) do
    case Map.fetch(template, "subsystem_state_hints") do
      :error ->
        issues

      {:ok, hints} when is_map(hints) ->
        ["required_states", "produced_states"]
        |> Enum.reduce(issues, fn field, acc ->
          acc
          |> validate_optional_type(
            "#{path}.subsystem_state_hints",
            hints,
            field,
            :list
          )
          |> validate_subsystem_state_hint_entries(
            "#{path}.subsystem_state_hints",
            hints,
            field
          )
        end)

      {:ok, _value} ->
        [error("#{path}.subsystem_state_hints", "must be a map") | issues]
    end
  end

  defp validate_subsystem_state_hint_entries(issues, path, hints, field) do
    case Map.get(hints, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = state_hint, index}, acc ->
            hint_path = "#{path}.#{field}[#{index}]"

            acc
            |> require_fields(hint_path, state_hint, ["subsystem", "state"])
            |> validate_optional_type(hint_path, state_hint, "subsystem", :binary)
            |> validate_optional_type(hint_path, state_hint, "state", :binary)
            |> validate_optional_type(hint_path, state_hint, "reason", :binary)
            |> validate_optional_type(hint_path, state_hint, "blocking", :boolean)

          {_state_hint, index}, acc ->
            [error("#{path}.#{field}[#{index}]", "must be a map") | acc]
        end)

      _value ->
        issues
    end
  end

  defp validate_precondition_hints(issues, path, template, capabilities) do
    case Map.fetch(template, "precondition_hints") do
      :error ->
        issues

      {:ok, hints} when is_list(hints) ->
        hints
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = hint, index}, acc ->
            hint_path = "#{path}.precondition_hints[#{index}]"

            acc
            |> require_fields(hint_path, hint, ["precondition_type"])
            |> expect_one_of(
              hint_path,
              hint,
              "precondition_type",
              capabilities.activity_precondition_types
            )
            |> validate_optional_one_of(
              hint_path,
              hint,
              "status",
              capabilities.activity_precondition_statuses
            )
            |> validate_optional_type(hint_path, hint, "reason", :binary)
            |> validate_optional_type(hint_path, hint, "field", :binary)
            |> validate_optional_type(hint_path, hint, "blocking", :boolean)

          {_hint, index}, acc ->
            [error("#{path}.precondition_hints[#{index}]", "must be a map") | acc]
        end)

      {:ok, _value} ->
        [error("#{path}.precondition_hints", "must be a list") | issues]
    end
  end
end
