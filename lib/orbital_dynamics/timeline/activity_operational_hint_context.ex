defmodule OrbitalDynamics.Timeline.ActivityOperationalHintContext do
  @moduledoc false

  def build(activity) do
    %{
      "setup_duration_s" => number(activity, "setup_duration_s"),
      "cooldown_duration_s" => number(activity, "cooldown_duration_s"),
      "telemetry_confirmation_required" =>
        boolean(activity, [
          "telemetry_confirmation_required",
          "telemetry_confirmation_required?"
        ]),
      "telemetry_confirmation_status" => string(activity, "telemetry_confirmation_status")
    }
    |> compact_map()
  end

  def number(activity, key) do
    case first_present_value(activity, [key]) do
      {:ok, value} ->
        numeric_value(value)

      :error ->
        activity
        |> activity_template_operational_hints()
        |> Map.get(key)
        |> numeric_value()
    end
  end

  def boolean(activity, keys) do
    case first_present_value(activity, keys) do
      {:ok, value} ->
        boolean_value(value)

      :error ->
        hints = activity_template_operational_hints(activity)

        keys
        |> Enum.find_value(fn key -> Map.get(hints, key) |> boolean_value() end)
    end
  end

  def string(activity, key) do
    case first_present_value(activity, [key]) do
      {:ok, value} when is_binary(value) and value != "" ->
        value

      {:ok, value} when is_atom(value) and not is_nil(value) ->
        Atom.to_string(value)

      {:ok, _value} ->
        nil

      :error ->
        case Map.get(activity_template_operational_hints(activity), key) do
          value when is_binary(value) and value != "" -> value
          value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
          _value -> nil
        end
    end
  end

  defp activity_template_operational_hints(activity) do
    case OrbitalDynamics.Timeline.ActivityTemplateProvenancePolicy.activity_template_provenance(
           activity
         ) do
      %{"operational_hints" => %{} = hints} -> hints
      _provenance -> %{}
    end
  end

  defp first_present_value(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_present_value(activity, keys)
  end

  defp numeric_value(value) do
    OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value(value)
  end

  defp boolean_value(value) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.boolean_value(value)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
