defmodule OrbitalDynamics.MissionPlan.Activity.PreconditionSummary do
  @moduledoc false

  alias OrbitalDynamics.Frame

  def build(activity, unit_interval_fields) do
    preconditions =
      activity
      |> rows(unit_interval_fields)
      |> Enum.sort_by(&{&1["status"], &1["type"], &1["field"]})

    blocked = Enum.filter(preconditions, &(&1["status"] == "blocked"))
    review = Enum.filter(preconditions, &(&1["status"] == "review_required"))

    %{
      "model" => "typed_activity_precondition_summary",
      "activity_id" => artifact_value(activity.id),
      "activity_type" => artifact_value(activity.type),
      "precondition_status" => status(blocked, review),
      "blocked_precondition_count" => length(blocked),
      "review_precondition_count" => length(review),
      "blocked_precondition_types" => types(blocked),
      "review_precondition_types" => types(review),
      "preconditions" => preconditions,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_precondition_summary",
        "resource_authority" => "not_reserved_by_precondition_summary"
      }
    }
  end

  defp rows(activity, unit_interval_fields) do
    []
    |> maybe_add(
      activity.spacecraft_available == false,
      "spacecraft_unavailable",
      "blocked",
      "spacecraft_available",
      "spacecraft availability is explicitly false"
    )
    |> maybe_add(
      activity.payload_available == false,
      "payload_unavailable",
      "blocked",
      "payload_available",
      "payload availability is explicitly false"
    )
    |> maybe_add(
      activity.antenna_available == false,
      "antenna_unavailable",
      "blocked",
      "antenna_available",
      "antenna availability is explicitly false"
    )
    |> maybe_add(
      activity.degraded == true,
      "degraded_mode",
      "review_required",
      "degraded",
      "activity is explicitly marked degraded"
    )
    |> maybe_add(
      not is_nil(activity.resource_blocking_dimension),
      "resource_block_declared",
      "blocked",
      "resource_blocking_dimension",
      "resource blocking dimension is explicitly declared",
      artifact_value(activity.resource_blocking_dimension)
    )
    |> maybe_add_margin_preconditions(activity, unit_interval_fields)
    |> maybe_add_activity_type_membership_precondition(
      activity,
      activity.incompatible_activity_types,
      "activity_type_incompatible",
      "incompatible_activity_types",
      "activity type appears in incompatible activity types"
    )
    |> maybe_add_activity_type_membership_precondition(
      activity,
      activity.suppressed_activity_types,
      "activity_type_suppressed",
      "suppressed_activity_types",
      "activity type appears in suppressed activity types"
    )
    |> maybe_add_command_authority_precondition(activity)
    |> maybe_add_command_safety_preconditions(activity)
    |> add_activity_template_required_state_preconditions(activity)
  end

  defp maybe_add_command_authority_precondition(preconditions, activity) do
    case command_authority_precondition_evidence(activity) do
      nil ->
        preconditions

      {field, value, reason} ->
        maybe_add(
          preconditions,
          true,
          "command_authority_missing",
          "review_required",
          field,
          reason,
          value
        )
    end
  end

  defp command_authority_precondition_evidence(activity) do
    metadata = activity_command_metadata(activity)
    authorized? = metadata_boolean(metadata, :command_authorized, :authority_granted)
    status = metadata_token(metadata, :command_authority_status, :authority_status)
    status_value = metadata_value(metadata, :command_authority_status, :authority_status)

    required_authority =
      metadata_value(metadata, :required_authority, :required_escalation_authority)

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
        {"command_authority_status", status_value,
         "command authority status requires operator review"}

      not is_nil(required_authority) and authorized? != true ->
        {"required_authority", required_authority, "required command authority is declared"}

      true ->
        nil
    end
  end

  defp maybe_add_command_safety_preconditions(preconditions, activity) do
    metadata = activity_command_metadata(activity)
    safety_status = metadata_token(metadata, :command_safety_status, :safety_status)
    safety_status_value = metadata_value(metadata, :command_safety_status, :safety_status)
    safety_checked? = metadata_boolean(metadata, :command_safety_checked, :safety_checked)

    preconditions
    |> maybe_add(
      safety_status in ["failed", "fail", "unsafe", "blocked", "rejected"],
      "command_safety_failed",
      "blocked",
      "command_safety_status",
      "command safety status is explicitly unsafe or failed",
      safety_status_value
    )
    |> maybe_add(
      safety_checked? == false or
        safety_status in ["missing", "required", "unchecked", "not_checked", "pending"],
      "command_safety_unchecked",
      "review_required",
      if(safety_checked? == false, do: "command_safety_checked", else: "command_safety_status"),
      "command safety check requires review before command handoff",
      if(safety_checked? == false, do: false, else: safety_status_value)
    )
  end

  defp activity_command_metadata(%{metadata: metadata}) when is_map(metadata) do
    artifact_value(metadata)
  end

  defp activity_command_metadata(_activity), do: %{}

  defp metadata_value(metadata, key, aliases) do
    aliases = List.wrap(aliases)

    Enum.reduce_while([key | aliases], nil, fn key, _acc ->
      value = field(metadata, key)

      if is_nil(value) do
        {:cont, nil}
      else
        {:halt, artifact_value(value)}
      end
    end)
  end

  defp metadata_token(metadata, key, aliases) do
    case metadata_value(metadata, key, aliases) do
      value when is_binary(value) -> normalized_token(value)
      value when is_atom(value) -> value |> Atom.to_string() |> normalized_token()
      _value -> nil
    end
  end

  defp metadata_boolean(metadata, key, aliases) do
    case metadata_value(metadata, key, aliases) do
      value when value in [true, "true", "1", 1] -> true
      value when value in [false, "false", "0", 0] -> false
      _value -> nil
    end
  end

  defp add_activity_template_required_state_preconditions(preconditions, activity) do
    activity
    |> activity_template_required_states()
    |> Enum.reduce(preconditions, fn {index, %{"subsystem" => subsystem, "state" => state} = hint},
                                     rows ->
      maybe_add(
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
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      )
    end)
  end

  defp activity_template_required_states(%{metadata: metadata}) when is_map(metadata) do
    metadata
    |> artifact_value()
    |> Map.get("activity_template")
    |> valid_activity_template_provenance()
    |> get_in(["subsystem_state_hints", "required_states"])
    |> valid_required_state_hints()
  end

  defp activity_template_required_states(_activity), do: []

  defp valid_activity_template_provenance(%{} = template) do
    if template["schema_contract"] == "activity_template.v1" and
         is_binary(template["id"]) and
         is_binary(template["activity_type"]) do
      template
    end
  end

  defp valid_activity_template_provenance(_template), do: nil

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

  defp maybe_add_margin_preconditions(preconditions, activity, unit_interval_fields) do
    unit_interval_fields
    |> Enum.filter(&(Map.get(activity, &1) == 0.0))
    |> Enum.reduce(preconditions, fn field, rows ->
      maybe_add(
        rows,
        true,
        "#{field}_depleted",
        "blocked",
        Atom.to_string(field),
        "unit-interval resource margin is depleted",
        0.0
      )
    end)
  end

  defp maybe_add_activity_type_membership_precondition(
         preconditions,
         activity,
         activity_types,
         type,
         field,
         reason
       ) do
    normalized_activity_type = artifact_value(activity.type)
    normalized_activity_types = Enum.map(activity_types || [], &artifact_value/1)

    maybe_add(
      preconditions,
      normalized_activity_type in normalized_activity_types,
      type,
      "blocked",
      field,
      reason,
      normalized_activity_type
    )
  end

  defp maybe_add(preconditions, false, _type, _status, _field, _reason),
    do: preconditions

  defp maybe_add(preconditions, true, type, status, field, reason) do
    maybe_add(preconditions, true, type, status, field, reason, nil)
  end

  defp maybe_add(preconditions, false, _type, _status, _field, _reason, _value),
    do: preconditions

  defp maybe_add(preconditions, true, type, status, field, reason, value) do
    row =
      %{
        "type" => type,
        "status" => status,
        "field" => field,
        "reason" => reason,
        "value" => value
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    [row | preconditions]
  end

  defp status([_blocked | _rest], _review), do: "blocked"
  defp status([], [_review | _rest]), do: "review_required"
  defp status([], []), do: "clear"

  defp types(preconditions) do
    preconditions
    |> Enum.map(& &1["type"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalized_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp field(map, key) when is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> Map.get(map, Atom.to_string(key))
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp artifact_value(value) when is_boolean(value) or is_nil(value), do: value
  defp artifact_value(value) when is_atom(value), do: Atom.to_string(value)
  defp artifact_value(%Frame{} = frame), do: artifact_value(frame.name)

  defp artifact_value(%{} = map) do
    Map.new(map, fn {key, value} ->
      key = if is_atom(key), do: Atom.to_string(key), else: key
      {key, artifact_value(value)}
    end)
  end

  defp artifact_value(values) when is_list(values), do: Enum.map(values, &artifact_value/1)
  defp artifact_value({x, y, z}), do: [artifact_value(x), artifact_value(y), artifact_value(z)]
  defp artifact_value(value), do: value
end
