defmodule OrbitalDynamics.Timeline.ActivityPreconditionContext do
  @moduledoc false

  def build(activity, callbacks) when is_list(callbacks) do
    preconditions =
      activity
      |> activity_precondition_rows(callbacks)
      |> Enum.sort_by(&{&1["status"], &1["type"], &1["field"]})

    blocked = Enum.filter(preconditions, &(&1["status"] == "blocked"))
    review = Enum.filter(preconditions, &(&1["status"] == "review_required"))

    %{
      "precondition_status" => precondition_status(blocked, review),
      "blocked_precondition_count" => length(blocked),
      "review_precondition_count" => length(review),
      "blocked_precondition_types" => precondition_types(blocked),
      "review_precondition_types" => precondition_types(review),
      "preconditions" => preconditions
    }
  end

  defp activity_precondition_rows(activity, callbacks) do
    []
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["spacecraft_available"], callbacks) == false,
      "spacecraft_unavailable",
      "blocked",
      "spacecraft_available",
      "spacecraft availability is explicitly false",
      callbacks
    )
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["payload_available"], callbacks) == false,
      "payload_unavailable",
      "blocked",
      "payload_available",
      "payload availability is explicitly false",
      callbacks
    )
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["antenna_available"], callbacks) == false,
      "antenna_unavailable",
      "blocked",
      "antenna_available",
      "antenna availability is explicitly false",
      callbacks
    )
    |> maybe_add_activity_precondition(
      first_boolean(activity, ["degraded"], callbacks) == true,
      "degraded_mode",
      "review_required",
      "degraded",
      "activity is explicitly marked degraded",
      callbacks
    )
    |> maybe_add_activity_precondition(
      not is_nil(first_value(activity, ["resource_blocking_dimension"], callbacks)),
      "resource_block_declared",
      "blocked",
      "resource_blocking_dimension",
      "resource blocking dimension is explicitly declared",
      encode_value(
        first_value(activity, ["resource_blocking_dimension"], callbacks),
        callbacks
      ),
      callbacks
    )
    |> maybe_add_depleted_margin_preconditions(activity, callbacks)
    |> maybe_add_activity_type_membership_precondition(
      activity,
      first_value(activity, ["incompatible_activity_types"], callbacks),
      "activity_type_incompatible",
      "incompatible_activity_types",
      "activity type appears in incompatible activity types",
      callbacks
    )
    |> maybe_add_activity_type_membership_precondition(
      activity,
      first_value(activity, ["suppressed_activity_types"], callbacks),
      "activity_type_suppressed",
      "suppressed_activity_types",
      "activity type appears in suppressed activity types",
      callbacks
    )
    |> maybe_add_command_authority_precondition(activity, callbacks)
    |> maybe_add_command_safety_preconditions(activity, callbacks)
    |> add_activity_template_required_state_preconditions(activity, callbacks)
  end

  defp maybe_add_command_authority_precondition(preconditions, activity, callbacks) do
    case command_authority_precondition_evidence(activity, callbacks) do
      nil ->
        preconditions

      {field, value, reason} ->
        maybe_add_activity_precondition(
          preconditions,
          true,
          "command_authority_missing",
          "review_required",
          field,
          reason,
          value,
          callbacks
        )
    end
  end

  defp command_authority_precondition_evidence(activity, callbacks) do
    authorized? =
      first_boolean(
        activity,
        ["command_authorized", "command_authorized?", "authority_granted"],
        callbacks
      )

    status =
      activity
      |> first_scalar_string(["command_authority_status", "authority_status"], callbacks)
      |> normalized_token(callbacks)

    required_authority =
      first_scalar_string(
        activity,
        ["required_authority", "required_escalation_authority"],
        callbacks
      )

    cond do
      authorized? == false ->
        {"command_authorized", false, "command authority is explicitly not granted"}

      status in [
        "missing",
        "authority_missing",
        "required",
        "operator_required",
        "review_required",
        "pending",
        "not_authorized",
        "unauthorized"
      ] ->
        {"command_authority_status",
         first_scalar_string(
           activity,
           ["command_authority_status", "authority_status"],
           callbacks
         ), "command authority status requires operator review"}

      not is_nil(required_authority) and authorized? != true ->
        {"required_authority", required_authority, "required command authority is declared"}

      true ->
        nil
    end
  end

  defp maybe_add_command_safety_preconditions(preconditions, activity, callbacks) do
    safety_status =
      activity
      |> first_scalar_string(["command_safety_status", "safety_status"], callbacks)
      |> normalized_token(callbacks)

    safety_checked? =
      first_boolean(
        activity,
        [
          "command_safety_checked",
          "command_safety_checked?",
          "safety_checked"
        ],
        callbacks
      )

    preconditions
    |> maybe_add_activity_precondition(
      safety_status in ["failed", "fail", "unsafe", "blocked", "rejected"],
      "command_safety_failed",
      "blocked",
      "command_safety_status",
      "command safety status is explicitly unsafe or failed",
      first_scalar_string(activity, ["command_safety_status", "safety_status"], callbacks),
      callbacks
    )
    |> maybe_add_activity_precondition(
      safety_checked? == false or
        safety_status in ["missing", "required", "unchecked", "not_checked", "pending"],
      "command_safety_unchecked",
      "review_required",
      if(safety_checked? == false, do: "command_safety_checked", else: "command_safety_status"),
      "command safety check requires review before command handoff",
      if(safety_checked? == false,
        do: false,
        else: first_scalar_string(activity, ["command_safety_status", "safety_status"], callbacks)
      ),
      callbacks
    )
  end

  defp add_activity_template_required_state_preconditions(preconditions, activity, callbacks) do
    activity
    |> activity_template_required_states(callbacks)
    |> Enum.reduce(preconditions, fn {index, %{"subsystem" => subsystem, "state" => state} = hint},
                                     rows ->
      maybe_add_activity_precondition(
        rows,
        true,
        "subsystem_state_required",
        "review_required",
        "activity_template.subsystem_state_hints.required_states[#{index}]",
        Map.get(hint, "reason") || "activity template declares required subsystem state",
        %{
          "subsystem" => subsystem,
          "state" => state,
          "blocking" => Map.get(hint, "blocking")
        }
        |> compact_map(callbacks),
        callbacks
      )
    end)
  end

  defp activity_template_required_states(activity, callbacks) do
    activity
    |> activity_template_required_state_sources(callbacks)
    |> Enum.find_value([], fn template ->
      template
      |> get_in(["subsystem_state_hints", "required_states"])
      |> valid_required_state_hints()
      |> case do
        [] -> nil
        hints -> hints
      end
    end)
  end

  defp activity_template_required_state_sources(activity, callbacks) do
    [
      activity_template_provenance(activity, callbacks),
      activity_template_provenance(
        %{
          "activity_template" => get_in(activity, ["activity_context", "activity_template"])
        },
        callbacks
      )
    ]
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys(&1, callbacks))
  end

  defp valid_required_state_hints(hints) when is_list(hints) do
    hints
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"subsystem" => subsystem, "state" => state} = hint, index}
      when is_binary(subsystem) and is_binary(state) ->
        [{index, hint}]

      _hint ->
        []
    end)
  end

  defp valid_required_state_hints(_hints), do: []

  defp maybe_add_depleted_margin_preconditions(preconditions, activity, callbacks) do
    Enum.reduce(
      Keyword.fetch!(callbacks, :unit_interval_activity_field_aliases),
      preconditions,
      fn {field, aliases}, rows ->
        maybe_add_activity_precondition(
          rows,
          first_number(activity, aliases, callbacks) == 0.0,
          "#{field}_depleted",
          "blocked",
          field,
          "unit-interval resource margin is depleted",
          0.0,
          callbacks
        )
      end
    )
  end

  defp maybe_add_activity_type_membership_precondition(
         preconditions,
         activity,
         activity_types,
         type,
         field,
         reason,
         callbacks
       ) do
    activity_type = Map.get(activity, "type")
    activity_types = normalize_id_list(activity_types, [], callbacks) || []

    maybe_add_activity_precondition(
      preconditions,
      activity_type in activity_types,
      type,
      "blocked",
      field,
      reason,
      activity_type,
      callbacks
    )
  end

  defp maybe_add_activity_precondition(
         preconditions,
         false,
         _type,
         _status,
         _field,
         _reason,
         _callbacks
       ),
       do: preconditions

  defp maybe_add_activity_precondition(
         preconditions,
         true,
         type,
         status,
         field,
         reason,
         callbacks
       ) do
    maybe_add_activity_precondition(
      preconditions,
      true,
      type,
      status,
      field,
      reason,
      nil,
      callbacks
    )
  end

  defp maybe_add_activity_precondition(
         preconditions,
         false,
         _type,
         _status,
         _field,
         _reason,
         _value,
         _callbacks
       ),
       do: preconditions

  defp maybe_add_activity_precondition(
         preconditions,
         true,
         type,
         status,
         field,
         reason,
         value,
         callbacks
       ) do
    row =
      %{
        "type" => type,
        "status" => status,
        "field" => field,
        "reason" => reason,
        "value" => value
      }
      |> compact_map(callbacks)

    [row | preconditions]
  end

  defp precondition_status([_blocked | _rest], _review), do: "blocked"
  defp precondition_status([], [_review | _rest]), do: "review_required"
  defp precondition_status([], []), do: "clear"

  defp precondition_types(preconditions) do
    preconditions
    |> Enum.map(& &1["type"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp first_boolean(value, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :first_boolean), [value, fields])

  defp first_value(value, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :first_value), [value, fields])

  defp encode_value(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :encode_value), [value])

  defp first_number(value, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :first_number), [value, fields])

  defp first_scalar_string(value, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :first_scalar_string), [value, fields])

  defp normalized_token(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :normalized_token), [value])

  defp activity_template_provenance(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_template_provenance), [value])

  defp stringify_keys(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :stringify_keys), [value])

  defp normalize_id_list(value, map_keys, callbacks),
    do: apply(Keyword.fetch!(callbacks, :normalize_id_list), [value, map_keys])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
