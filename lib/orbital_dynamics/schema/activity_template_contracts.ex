defmodule OrbitalDynamics.Schema.ActivityTemplateContracts do
  @moduledoc false

  def validate(issues, path, template, contract, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, template, contract["required_fields"])
    |> expect_equal(callbacks, path, template, "schema_contract", "activity_template.v1")
    |> validate_stable_id(callbacks, path <> ".id", Map.get(template, "id"))
    |> expect_one_of(callbacks, path, template, "activity_type", activity_types(callbacks))
    |> validate_version(callbacks, path, template)
    |> expect_equal(callbacks, path, template, "validation_level", "artifact_contract")
    |> expect_type(callbacks, path, template, "known_limits", :list)
    |> validate_string_list_items(callbacks, path, template, "known_limits")
    |> validate_metadata_fields(callbacks, path, template)
    |> validate_field_lists(callbacks, path, template)
    |> validate_default_fields(callbacks, path, template)
    |> validate_lifecycle_defaults(callbacks, path, template)
    |> validate_operational_hints(callbacks, path, template)
    |> validate_subsystem_state_hints(callbacks, path, template)
    |> validate_resource_hints(callbacks, path, template)
    |> validate_precondition_hints(callbacks, path, template)
  end

  defp validate_version(issues, callbacks, path, template) do
    case Map.get(template, "template_version") do
      value when is_integer(value) and value >= 1 ->
        issues

      _value ->
        [
          error(
            callbacks,
            "#{path}.template_version",
            "must be an integer greater than or equal to 1"
          )
          | issues
        ]
    end
  end

  defp validate_metadata_fields(issues, callbacks, path, template) do
    issues
    |> validate_optional_type(callbacks, path, template, "display_name", :binary)
    |> validate_optional_type(callbacks, path, template, "description", :binary)
    |> validate_optional_type(callbacks, path, template, "assumptions", :map)
  end

  defp validate_optional_type(issues, callbacks, path, map, field, type) do
    if Map.has_key?(map, field) do
      expect_type(issues, callbacks, path, map, field, type)
    else
      issues
    end
  end

  defp validate_optional_one_of(issues, callbacks, path, map, field, allowed) do
    if Map.has_key?(map, field) do
      expect_one_of(issues, callbacks, path, map, field, allowed)
    else
      issues
    end
  end

  defp validate_optional_number(issues, callbacks, path, map, field) do
    case Map.fetch(map, field) do
      :error -> issues
      {:ok, value} when is_number(value) -> issues
      {:ok, _value} -> [error(callbacks, "#{path}.#{field}", "must be a number") | issues]
    end
  end

  defp validate_optional_non_negative_integer(issues, callbacks, path, map, field) do
    case Map.fetch(map, field) do
      :error ->
        issues

      {:ok, value} when is_integer(value) and value >= 0 ->
        issues

      {:ok, _value} ->
        [error(callbacks, "#{path}.#{field}", "must be a non-negative integer") | issues]
    end
  end

  defp validate_optional_non_negative_number(issues, callbacks, path, map, field) do
    case Map.fetch(map, field) do
      :error ->
        issues

      {:ok, value} when is_number(value) and value >= 0.0 ->
        issues

      {:ok, value} when is_number(value) ->
        [error(callbacks, "#{path}.#{field}", "must be non-negative") | issues]

      {:ok, _value} ->
        [error(callbacks, "#{path}.#{field}", "must be a number") | issues]
    end
  end

  defp validate_field_lists(issues, callbacks, path, template) do
    issues
    |> validate_optional_type(callbacks, path, template, "required_fields", :list)
    |> validate_string_list_items(callbacks, path, template, "required_fields")
    |> validate_optional_type(callbacks, path, template, "optional_fields", :list)
    |> validate_string_list_items(callbacks, path, template, "optional_fields")
    |> validate_optional_non_negative_integer(callbacks, path, template, "field_count")
    |> validate_optional_non_negative_integer(callbacks, path, template, "required_field_count")
    |> validate_optional_non_negative_integer(callbacks, path, template, "optional_field_count")
    |> expect_field_equals(
      callbacks,
      path,
      template,
      "required_field_count",
      list_count(callbacks, template, "required_fields"),
      "must equal required_fields count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      template,
      "optional_field_count",
      list_count(callbacks, template, "optional_fields"),
      "must equal optional_fields count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      template,
      "field_count",
      declared_field_count(callbacks, template),
      "must equal required_fields plus optional_fields count"
    )
  end

  defp declared_field_count(callbacks, template) do
    required_count = list_count(callbacks, template, "required_fields")
    optional_count = list_count(callbacks, template, "optional_fields")

    if is_integer(required_count) and is_integer(optional_count) do
      required_count + optional_count
    end
  end

  defp validate_default_fields(issues, callbacks, path, template) do
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
                callbacks,
                "#{path}.default_fields.#{field}",
                "must be declared in required_fields or optional_fields"
              )
              | acc
            ]
          end
        end)

      {:ok, _value} ->
        [error(callbacks, "#{path}.default_fields", "must be a map") | issues]
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

  defp validate_lifecycle_defaults(issues, callbacks, path, template) do
    case Map.fetch(template, "lifecycle_defaults") do
      :error ->
        issues

      {:ok, defaults} when is_map(defaults) ->
        issues
        |> validate_optional_one_of(
          callbacks,
          "#{path}.lifecycle_defaults",
          defaults,
          "status",
          activity_statuses(callbacks)
        )
        |> validate_optional_one_of(
          callbacks,
          "#{path}.lifecycle_defaults",
          defaults,
          "approval_status",
          approval_statuses(callbacks)
        )
        |> validate_optional_type(
          callbacks,
          "#{path}.lifecycle_defaults",
          defaults,
          "locked",
          :boolean
        )
        |> validate_optional_type(
          callbacks,
          "#{path}.lifecycle_defaults",
          defaults,
          "allow_overlap",
          :boolean
        )

      {:ok, _value} ->
        [error(callbacks, "#{path}.lifecycle_defaults", "must be a map") | issues]
    end
  end

  defp validate_operational_hints(issues, callbacks, path, template) do
    case Map.fetch(template, "operational_hints") do
      :error ->
        issues

      {:ok, hints} when is_map(hints) ->
        issues
        |> validate_optional_non_negative_number(
          callbacks,
          "#{path}.operational_hints",
          hints,
          "setup_duration_s"
        )
        |> validate_optional_non_negative_number(
          callbacks,
          "#{path}.operational_hints",
          hints,
          "cooldown_duration_s"
        )
        |> validate_optional_type(
          callbacks,
          "#{path}.operational_hints",
          hints,
          "telemetry_confirmation_required",
          :boolean
        )
        |> validate_optional_type(
          callbacks,
          "#{path}.operational_hints",
          hints,
          "telemetry_confirmation_status",
          :binary
        )

      {:ok, _value} ->
        [error(callbacks, "#{path}.operational_hints", "must be a map") | issues]
    end
  end

  defp validate_resource_hints(issues, callbacks, path, template) do
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
              callbacks,
              "#{path}.resource_hints",
              hints,
              field,
              :boolean
            )
          end)

        issues =
          Enum.reduce(string_list_fields, issues, fn field, acc ->
            acc
            |> validate_optional_type(callbacks, "#{path}.resource_hints", hints, field, :list)
            |> validate_string_list_items(callbacks, "#{path}.resource_hints", hints, field)
          end)

        issues =
          Enum.reduce(non_negative_number_fields, issues, fn field, acc ->
            validate_optional_non_negative_number(
              acc,
              callbacks,
              "#{path}.resource_hints",
              hints,
              field
            )
          end)

        Enum.reduce(number_fields, issues, fn field, acc ->
          validate_optional_number(acc, callbacks, "#{path}.resource_hints", hints, field)
        end)

      {:ok, _value} ->
        [error(callbacks, "#{path}.resource_hints", "must be a map") | issues]
    end
  end

  defp validate_subsystem_state_hints(issues, callbacks, path, template) do
    case Map.fetch(template, "subsystem_state_hints") do
      :error ->
        issues

      {:ok, hints} when is_map(hints) ->
        ["required_states", "produced_states"]
        |> Enum.reduce(issues, fn field, acc ->
          acc
          |> validate_optional_type(
            callbacks,
            "#{path}.subsystem_state_hints",
            hints,
            field,
            :list
          )
          |> validate_subsystem_state_hint_entries(
            callbacks,
            "#{path}.subsystem_state_hints",
            hints,
            field
          )
        end)

      {:ok, _value} ->
        [error(callbacks, "#{path}.subsystem_state_hints", "must be a map") | issues]
    end
  end

  defp validate_subsystem_state_hint_entries(issues, callbacks, path, hints, field) do
    case Map.get(hints, field) do
      values when is_list(values) ->
        values
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = state_hint, index}, acc ->
            hint_path = "#{path}.#{field}[#{index}]"

            acc
            |> require_fields(callbacks, hint_path, state_hint, ["subsystem", "state"])
            |> validate_optional_type(callbacks, hint_path, state_hint, "subsystem", :binary)
            |> validate_optional_type(callbacks, hint_path, state_hint, "state", :binary)
            |> validate_optional_type(callbacks, hint_path, state_hint, "reason", :binary)
            |> validate_optional_type(callbacks, hint_path, state_hint, "blocking", :boolean)

          {_state_hint, index}, acc ->
            [error(callbacks, "#{path}.#{field}[#{index}]", "must be a map") | acc]
        end)

      _value ->
        issues
    end
  end

  defp validate_precondition_hints(issues, callbacks, path, template) do
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
            |> require_fields(callbacks, hint_path, hint, ["precondition_type"])
            |> expect_one_of(
              callbacks,
              hint_path,
              hint,
              "precondition_type",
              precondition_types(callbacks)
            )
            |> validate_optional_one_of(
              callbacks,
              hint_path,
              hint,
              "status",
              precondition_statuses(callbacks)
            )
            |> validate_optional_type(callbacks, hint_path, hint, "reason", :binary)
            |> validate_optional_type(callbacks, hint_path, hint, "field", :binary)
            |> validate_optional_type(callbacks, hint_path, hint, "blocking", :boolean)

          {_hint, index}, acc ->
            [error(callbacks, "#{path}.precondition_hints[#{index}]", "must be a map") | acc]
        end)

      {:ok, _value} ->
        [error(callbacks, "#{path}.precondition_hints", "must be a list") | issues]
    end
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, values),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, values])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_stable_id(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id), [issues, path, value])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp list_count(callbacks, map, field),
    do: apply(Keyword.fetch!(callbacks, :list_count), [map, field])

  defp activity_types(callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_template_activity_types), [])

  defp activity_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_template_activity_statuses), [])

  defp approval_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_template_approval_statuses), [])

  defp precondition_types(callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_template_precondition_types), [])

  defp precondition_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_template_precondition_statuses), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
