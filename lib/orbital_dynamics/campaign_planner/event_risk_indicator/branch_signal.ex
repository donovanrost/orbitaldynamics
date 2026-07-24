defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.BranchSignal do
  @moduledoc false

  def indicators(%{"type" => "degraded_spacecraft"} = event) do
    spacecraft_id = branch_event_spacecraft_id(event)

    [
      %{
        "type" => "spacecraft_degraded",
        "severity" => "high",
        "reason" => "spacecraft #{spacecraft_id} degraded",
        "spacecraft_id" => spacecraft_id
      }
      |> compact_map()
    ]
    |> Kernel.++(degraded_spacecraft_activity_type_risks(event, spacecraft_id))
  end

  def indicators(%{"type" => type} = event)
      when type in ["missed_maneuver", "delayed_maneuver"] do
    [
      %{
        "type" => type,
        "severity" => "high",
        "reason" => "maneuver #{event["activity_id"]} affects downstream windows"
      }
    ]
  end

  def indicators(%{"type" => "fuel_preservation_mode"}) do
    [
      %{
        "type" => "fuel_preservation_mode",
        "severity" => "medium",
        "reason" => "fuel preservation changes branch scoring"
      }
    ]
  end

  def indicators(%{"type" => "urgent_target"} = event) do
    [
      %{
        "type" => "urgent_target",
        "severity" => "medium",
        "reason" => "urgent target #{event["target_id"]} inserted",
        "target_id" => event["target_id"],
        "observation_result" => event["observation_result"],
        "realized_status" => event["realized_status"],
        "source_activity_id" => event["source_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "trust_boundary" => event["trust_boundary"]
      }
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp degraded_spacecraft_activity_type_risks(event, spacecraft_id) do
    event
    |> Map.get("derivation_reasons", [])
    |> List.wrap()
    |> Enum.filter(&(&1 in projected_activity_type_constraint_reasons()))
    |> Enum.map(fn reason ->
      type = String.replace_prefix(reason, "projected_", "")

      %{
        "type" => type,
        "severity" => "high",
        "reason" =>
          "resource projection for #{spacecraft_id} constrains activity types #{Enum.join(Map.get(event, "incompatible_activity_types", []), ", ")}",
        "spacecraft_id" => spacecraft_id,
        "mode" => event["mode"],
        "incompatible_activity_types" => event["incompatible_activity_types"],
        "source_quality" => event["source_quality"],
        "source_activity_id" => event["source_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => [reason]
      }
      |> compact_map()
    end)
  end

  defp projected_activity_type_constraint_reasons do
    ~w(projected_activity_type_suppressed_by_resource_summary projected_activity_type_incompatible_with_resource_summary)
  end

  defp branch_event_spacecraft_id(event) do
    case encode_value(Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
