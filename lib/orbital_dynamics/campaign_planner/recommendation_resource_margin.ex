defmodule OrbitalDynamics.CampaignPlanner.RecommendationResourceMargin do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def rows(%PlanBranch{id: branch_id, events: events}) do
    events
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["type"] == "resource_margin_pressure"))
    |> Enum.map(fn event ->
      field = event["resource_field"] || "resource_margin"
      value = Map.get(event, field)
      threshold = Map.get(event, "#{field}_threshold")
      spacecraft_id = branch_event_spacecraft_id(event)

      %{
        "type" => "resource_margin_pressure",
        "recommended_branch_id" => branch_id,
        "risk_type" => field <> "_low",
        "resource_margin_risk_type" => field <> "_low",
        "severity" => "medium",
        "reason" => "spacecraft #{spacecraft_id} #{field} #{value} below threshold #{threshold}",
        "value" => value,
        "spacecraft_id" => spacecraft_id,
        "scenario_id" => event["scenario_id"],
        "timeline_id" => event["timeline_id"],
        "source_activity_id" => event["source_activity_id"],
        "replacement_activity_id" => event["replacement_activity_id"],
        "source_activity_ids" => event["source_activity_ids"],
        "resource_field" => field,
        "resource_margin_value" => value,
        "resource_margin_threshold" => threshold,
        "resource_margin_field_value" =>
          resource_margin_field_value_context(field, value, threshold),
        "source_quality" => event["source_quality"],
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "diff_status" => event["diff_status"],
        "changed_fields" => event["changed_fields"],
        "required_operator_action" => event["required_operator_action"],
        "requires_operator_review" => event["requires_operator_review"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    end)
  end

  def rows(_branch), do: []

  defp branch_event_spacecraft_id(event) do
    case encode_value(Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  defp resource_margin_field_value_context(field, value, threshold)
       when is_binary(field) and is_number(value) do
    %{
      "field" => field,
      "value" => value,
      "threshold" => threshold
    }
    |> compact_map()
  end

  defp resource_margin_field_value_context(_field, _value, _threshold), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(value), do: value

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
