defmodule OrbitalDynamics.Timeline.ActivityTemplateProvenancePolicy do
  @moduledoc false

  def activity_template_context(activity) do
    case activity_template_provenance(activity) do
      nil -> %{}
      provenance -> %{"activity_template" => provenance}
    end
  end

  def activity_template_provenance(%{"activity_template" => %{} = template}) do
    template = stringify_keys(template)

    if template["schema_contract"] == "activity_template.v1" and
         is_binary(template["id"]) and
         is_binary(template["activity_type"]) do
      template
      |> Map.take([
        "schema_contract",
        "id",
        "activity_type",
        "template_version",
        "validation_level",
        "known_limits",
        "operational_hints",
        "subsystem_state_hints",
        "assumptions"
      ])
      |> normalize_activity_template_provenance()
      |> compact_map()
    end
  end

  def activity_template_provenance(_activity), do: nil

  defp normalize_activity_template_provenance(%{"operational_hints" => hints} = template) do
    case normalize_activity_template_operational_hints(hints) do
      hints when is_map(hints) and map_size(hints) > 0 ->
        Map.put(template, "operational_hints", hints)

      _hints ->
        Map.delete(template, "operational_hints")
    end
  end

  defp normalize_activity_template_provenance(template), do: template

  defp normalize_activity_template_operational_hints(%{} = hints) do
    hints = stringify_keys(hints)

    hints
    |> Map.drop([
      "setup_duration_s",
      "cooldown_duration_s",
      "telemetry_confirmation_required",
      "telemetry_confirmation_status"
    ])
    |> maybe_put_operational_hint_number("setup_duration_s", Map.get(hints, "setup_duration_s"))
    |> maybe_put_operational_hint_number(
      "cooldown_duration_s",
      Map.get(hints, "cooldown_duration_s")
    )
    |> maybe_put_operational_hint_boolean(
      "telemetry_confirmation_required",
      Map.get(hints, "telemetry_confirmation_required")
    )
    |> maybe_put_operational_hint_string(
      "telemetry_confirmation_status",
      Map.get(hints, "telemetry_confirmation_status")
    )
    |> compact_map()
  end

  defp normalize_activity_template_operational_hints(_hints), do: nil

  defp maybe_put_operational_hint_number(hints, key, value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0.0 -> Map.put(hints, key, number)
      _value -> hints
    end
  end

  defp maybe_put_operational_hint_boolean(hints, key, value) do
    case boolean_value(value) do
      value when is_boolean(value) -> Map.put(hints, key, value)
      _value -> hints
    end
  end

  defp maybe_put_operational_hint_string(hints, key, value) when is_binary(value) do
    case String.trim(value) do
      "" -> hints
      value -> Map.put(hints, key, value)
    end
  end

  defp maybe_put_operational_hint_string(hints, key, value)
       when is_atom(value) and not is_nil(value),
       do: Map.put(hints, key, Atom.to_string(value))

  defp maybe_put_operational_hint_string(hints, _key, _value), do: hints

  defp stringify_keys(value) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.stringify_keys(value)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end

  defp numeric_value(value) do
    OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value(value)
  end

  defp boolean_value(value) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.boolean_value(value)
  end
end
