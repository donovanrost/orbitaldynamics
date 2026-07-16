defmodule OrbitalDynamics.OperatorReview.RepairReview do
  @moduledoc false

  def plan_delta_rows(deltas, source) do
    deltas
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {delta, index} ->
      repair_action = Map.get(delta, "repair_action", "unknown")
      action = plan_delta_operator_action(repair_action)
      source_import_context = plan_delta_import_context(delta, "source")
      replacement_import_context = plan_delta_import_context(delta, "replacement")

      source_activity_context =
        plan_delta_activity_context(delta["source_activity_context"], source_import_context)

      replacement_activity_context =
        plan_delta_activity_context(
          delta["replacement_activity_context"],
          replacement_import_context
        )

      %{
        "id" => review_id(["plan_delta", delta["activity_id"], repair_action, index]),
        "review_type" => "plan_delta_review",
        "source" => source,
        "subject_id" => delta["activity_id"],
        "activity_id" => delta["activity_id"],
        "activity_type" => delta["activity_type"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => plan_delta_approval_status(delta),
        "repair_action" => repair_action,
        "reason" => Map.get(delta, "reason", "review #{repair_action} repair delta"),
        "source_timeline_id" => delta["source_timeline_id"],
        "replacement_activity_id" => delta["replacement_activity_id"],
        "replacement_timeline_id" => delta["replacement_timeline_id"],
        "timeline_link" => delta["timeline_link"],
        "source_activity_context" => source_activity_context,
        "replacement_activity_context" => replacement_activity_context,
        "source_timeline_identity" => plan_delta_source_timeline_identity(delta),
        "replacement_timeline_identity" => plan_delta_replacement_timeline_identity(delta),
        "source_cadence_import_status" => source_import_context["cadence_import_status"],
        "source_cadence_import_type" => source_import_context["cadence_import_type"],
        "source_cadence_import_id" => source_import_context["cadence_import_id"],
        "source_cadence_import_contract" => source_import_context["cadence_import_contract"],
        "source_has_cadence_import" => source_import_context["has_cadence_import"],
        "replacement_cadence_import_status" =>
          replacement_import_context["cadence_import_status"],
        "replacement_cadence_import_type" => replacement_import_context["cadence_import_type"],
        "replacement_cadence_import_id" => replacement_import_context["cadence_import_id"],
        "replacement_cadence_import_contract" =>
          replacement_import_context["cadence_import_contract"],
        "replacement_has_cadence_import" => replacement_import_context["has_cadence_import"],
        "invalid_cadence_import" =>
          source_import_context["invalid_cadence_import"] ||
            replacement_import_context["invalid_cadence_import"],
        "invalid_cadence_import_reason" =>
          source_import_context["invalid_cadence_import_reason"] ||
            replacement_import_context["invalid_cadence_import_reason"],
        "source_cadence_import" =>
          plan_delta_invalid_cadence_import_evidence(
            source_import_context,
            replacement_import_context
          ),
        "source_delta" => delta
      }
      |> compact_map()
    end)
  end

  def timeline_protection_rows(nil, _source), do: []

  def timeline_protection_rows(%{} = protection, source) do
    protection = stringify_keys(protection)

    [
      {"preserved_locked_or_approved", "preserved", "preserved_locked_or_approved_activity_ids",
       "record_protected_timeline_preservation",
       "locked or approved activity preserved by repair policy", "not_required"},
      {"preserved_executed", "preserved", "preserved_executed_activity_ids",
       "record_executed_timeline_preservation", "executed activity preserved by repair policy",
       "not_required"},
      {"changed_locked_or_approved", "changed", "changed_locked_or_approved_activity_ids",
       "review_changed_protected_timeline_item", "locked or approved activity changed by repair",
       "operator_review_required"},
      {"changed_executed", "changed", "changed_executed_activity_ids",
       "review_changed_executed_timeline_item", "executed activity changed by repair",
       "operator_review_required"}
    ]
    |> Enum.flat_map(fn {category, decision, id_field, action, reason, approval_status} ->
      protection
      |> Map.get(id_field, [])
      |> Enum.map(&encode_value/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {activity_id, index} ->
        %{
          "id" => review_id(["timeline_protection", category, activity_id, index]),
          "review_type" => "timeline_protection",
          "source" => source,
          "subject_id" => activity_id,
          "activity_id" => activity_id,
          "action" => action,
          "required_operator_action" => action,
          "approval_status" => approval_status,
          "reason" => reason,
          "protection_category" => category,
          "protection_decision" => decision,
          "source_timeline_protection" => protection
        }
      end)
    end)
  end

  defp plan_delta_operator_action("preserved"), do: "record_preserved_timeline_item"
  defp plan_delta_operator_action("preserved_executed"), do: "record_preserved_executed_item"
  defp plan_delta_operator_action("moved"), do: "review_moved_timeline_item"
  defp plan_delta_operator_action("replaced"), do: "review_replaced_timeline_item"
  defp plan_delta_operator_action("suppressed"), do: "review_suppressed_timeline_item"
  defp plan_delta_operator_action("canceled"), do: "review_canceled_timeline_item"
  defp plan_delta_operator_action("review_realized_feedback"), do: "review_realized_feedback"
  defp plan_delta_operator_action(_action), do: "review_plan_delta"

  defp plan_delta_approval_status(%{"requires_approval" => false}), do: "not_required"
  defp plan_delta_approval_status(_delta), do: "operator_review_required"

  defp plan_delta_source_timeline_identity(delta) do
    get_in(delta, ["source_activity_context", "timeline_identity"]) ||
      get_in(delta, ["planned", "timeline_identity"])
  end

  defp plan_delta_replacement_timeline_identity(delta) do
    get_in(delta, ["replacement_activity_context", "timeline_identity"])
  end

  defp plan_delta_import_context(delta, side) do
    context = Map.get(delta, "#{side}_activity_context", %{}) || %{}
    context = if is_map(context), do: context, else: %{}
    raw_cadence_import = Map.get(context, "cadence_import")
    cadence_import = if is_map(raw_cadence_import), do: raw_cadence_import, else: %{}
    activity_type = plan_delta_context_activity_type(delta, side, context)
    has_import? = is_map(raw_cadence_import)
    invalid_import? = Map.has_key?(context, "cadence_import") and not has_import?

    %{
      "cadence_import_status" =>
        if(invalid_import?,
          do: "invalid",
          else: plan_delta_cadence_import_status(has_import?, activity_type, context)
        ),
      "cadence_import_type" => get_in(cadence_import, ["activity_type"]),
      "cadence_import_id" => get_in(cadence_import, ["external_id"]),
      "cadence_import_contract" => get_in(cadence_import, ["schema_contract"]),
      "has_cadence_import" => has_import?,
      "invalid_cadence_import" => if(invalid_import?, do: true),
      "invalid_cadence_import_reason" => if(invalid_import?, do: "cadence_import_must_be_object"),
      "source_cadence_import" =>
        if(invalid_import?,
          do: %{"invalid_import_shape" => stringify_keys(raw_cadence_import)}
        )
    }
  end

  defp plan_delta_activity_context(
         %{} = context,
         %{"invalid_cadence_import" => true} = import_context
       ) do
    context
    |> Map.delete("cadence_import")
    |> Map.put("invalid_cadence_import", true)
    |> Map.put("invalid_cadence_import_reason", import_context["invalid_cadence_import_reason"])
    |> Map.put("source_cadence_import", import_context["source_cadence_import"])
  end

  defp plan_delta_activity_context(%{} = context, _import_context), do: context
  defp plan_delta_activity_context(_context, _import_context), do: nil

  defp plan_delta_invalid_cadence_import_evidence(source_context, replacement_context) do
    %{
      "source" => source_context["source_cadence_import"],
      "replacement" => replacement_context["source_cadence_import"]
    }
    |> compact_map()
    |> empty_to_nil()
  end

  defp plan_delta_context_activity_type(delta, "source", context) do
    get_in(context, ["timeline_identity", "activity_type"]) || delta["activity_type"]
  end

  defp plan_delta_context_activity_type(_delta, "replacement", context) do
    get_in(context, ["timeline_identity", "activity_type"])
  end

  defp plan_delta_cadence_import_status(true, _activity_type, _context), do: "present"

  defp plan_delta_cadence_import_status(false, activity_type, context) do
    cond do
      activity_type in ["downlink", "planned_contact", "tracking", "command", "health_check"] ->
        "missing"

      context["direction"] == "command" ->
        "missing"

      is_binary(context["ground_station_id"]) and context["ground_station_id"] != "" ->
        "missing"

      true ->
        "not_applicable"
    end
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp empty_to_nil(map) when map == %{}, do: nil
  defp empty_to_nil(map), do: map
end
