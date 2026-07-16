defmodule OrbitalDynamics.CampaignPlanner.SpacecraftResourceFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchOperationalFeedback,
    OperationalFeedbackSourceMetadata,
    ScalarValues,
    ValueEncoding
  }

  def margin(overrides, policy, horizon_end_s, trust_boundary) do
    margin(overrides, policy, horizon_end_s, trust_boundary, callbacks())
  end

  def margin(overrides, policy, horizon_end_s, trust_boundary, callbacks)
      when is_map(overrides) do
    overrides
    |> Enum.flat_map(fn {spacecraft_id, margins} ->
      margins
      |> stringify_keys(callbacks)
      |> spacecraft_margin_events(
        to_string(spacecraft_id),
        policy,
        horizon_end_s,
        trust_boundary,
        callbacks
      )
    end)
    |> Enum.sort_by(&{&1["spacecraft_id"], &1["resource_field"]})
  end

  def availability(overrides, horizon_end_s, trust_boundary) do
    availability(overrides, horizon_end_s, trust_boundary, callbacks())
  end

  def availability(overrides, horizon_end_s, trust_boundary, callbacks)
      when is_map(overrides) do
    overrides
    |> Enum.flat_map(fn {spacecraft_id, availability} ->
      availability
      |> stringify_keys(callbacks)
      |> spacecraft_availability_events(
        to_string(spacecraft_id),
        horizon_end_s,
        trust_boundary,
        callbacks
      )
    end)
    |> Enum.sort_by(&{&1["spacecraft_id"], &1["resource_field"]})
  end

  defp spacecraft_margin_events(
         margins,
         spacecraft_id,
         policy,
         horizon_end_s,
         trust_boundary,
         callbacks
       )
       when is_map(margins) and spacecraft_id not in ["", "nil"] do
    ["fuel_margin", "power_margin", "storage_margin", "downlink_margin", "thermal_margin_c"]
    |> Enum.flat_map(fn field ->
      value = Map.get(margins, field)
      threshold = resource_margin_feedback_threshold(policy, field)

      if is_number(value) and is_number(threshold) and value <= threshold do
        [
          margin_event(
            spacecraft_id,
            field,
            value,
            threshold,
            horizon_end_s,
            trust_boundary,
            callbacks
          )
        ]
      else
        []
      end
    end)
  end

  defp spacecraft_margin_events(
         _margins,
         _spacecraft_id,
         _policy,
         _horizon_end_s,
         _trust_boundary,
         _callbacks
       ),
       do: []

  defp spacecraft_availability_events(
         availability,
         spacecraft_id,
         horizon_end_s,
         trust_boundary,
         callbacks
       )
       when is_map(availability) and spacecraft_id not in ["", "nil"] do
    degraded_events =
      if degraded_availability_feedback?(availability, callbacks) do
        [
          degraded_spacecraft_event(
            spacecraft_id,
            availability,
            horizon_end_s,
            trust_boundary,
            callbacks
          )
        ]
      else
        []
      end

    resource_events =
      ["payload_available", "antenna_available"]
      |> Enum.flat_map(fn field ->
        case Map.get(availability, field) do
          false ->
            [
              availability_event(
                spacecraft_id,
                field,
                availability_feedback_reason(field),
                horizon_end_s,
                trust_boundary,
                callbacks
              )
            ]

          _value ->
            []
        end
      end)

    degraded_events ++ resource_events
  end

  defp spacecraft_availability_events(
         _availability,
         _spacecraft_id,
         _horizon_end_s,
         _trust_boundary,
         _callbacks
       ),
       do: []

  defp resource_margin_feedback_threshold(policy, "thermal_margin_c"),
    do: Map.get(policy, "thermal_margin_c_threshold")

  defp resource_margin_feedback_threshold(policy, field),
    do: Map.get(policy, "#{field}_threshold")

  defp margin_event(
         spacecraft_id,
         field,
         value,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "resource_margin_pressure",
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      field => value * 1.0,
      "#{field}_threshold" => threshold,
      "derivation_reasons" => ["#{field}_feedback_low"],
      "feedback_source" => "operational_feedback.resource_margin_overrides",
      "feedback_scope" => "spacecraft",
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "resource_margin_overrides",
          spacecraft_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp availability_event(spacecraft_id, field, reason, horizon_end_s, trust_boundary, callbacks) do
    %{
      "type" => "resource_availability_constraint",
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      "available" => false,
      "derivation_reasons" => [reason],
      "feedback_source" => "operational_feedback.resource_availability_overrides",
      "feedback_scope" => "spacecraft",
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "resource_availability_overrides",
          spacecraft_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp availability_feedback_reason("payload_available"),
    do: "payload_availability_feedback_false"

  defp availability_feedback_reason("antenna_available"),
    do: "antenna_availability_feedback_false"

  defp degraded_availability_feedback?(availability, callbacks) do
    truthy?(Map.get(availability, "degraded"), callbacks) or
      Map.get(availability, "mode") in ["degraded", "degraded_mode", "safe"] or
      Map.get(availability, "spacecraft_available") == false or
      Map.get(availability, "spacecraft_availability") == false
  end

  defp degraded_spacecraft_event(
         spacecraft_id,
         availability,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "degraded_spacecraft",
      "scenario_id" => spacecraft_id,
      "spacecraft_id" => spacecraft_id,
      "mode" => Map.get(availability, "mode", "degraded"),
      "incompatible_activity_types" =>
        availability_incompatible_activity_types(availability, callbacks),
      "derivation_reasons" => degraded_availability_feedback_reasons(availability, callbacks),
      "feedback_source" => "operational_feedback.resource_availability_overrides",
      "feedback_scope" => "spacecraft",
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "resource_availability_overrides",
          spacecraft_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp availability_incompatible_activity_types(availability, callbacks) do
    explicit =
      Map.get(availability, "incompatible_activity_types") ||
        Map.get(availability, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        normalize_incompatible_activity_types(explicit, callbacks)

      Map.get(availability, "spacecraft_available") == false or
          Map.get(availability, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      true ->
        degradation_incompatible_activity_types(availability, callbacks)
    end
  end

  defp degraded_availability_feedback_reasons(availability, callbacks) do
    [
      if(truthy?(Map.get(availability, "degraded"), callbacks),
        do: "spacecraft_degraded_feedback_true"
      ),
      if(Map.get(availability, "mode") in ["degraded", "degraded_mode", "safe"],
        do: "spacecraft_mode_feedback_#{Map.get(availability, "mode")}"
      ),
      if(Map.get(availability, "spacecraft_available") == false,
        do: "spacecraft_available_feedback_false"
      ),
      if(Map.get(availability, "spacecraft_availability") == false,
        do: "spacecraft_availability_feedback_false"
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp stringify_keys(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:stringify_keys)
    |> then(& &1.(value))
  end

  defp compact_map(map, callbacks) do
    callbacks
    |> Keyword.fetch!(:compact_map)
    |> then(& &1.(map))
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key, callbacks) do
    callbacks
    |> Keyword.fetch!(:feedback_event_trust_boundary)
    |> then(& &1.(trust_boundary, field, key))
  end

  defp truthy?(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:truthy?)
    |> then(& &1.(value))
  end

  defp normalize_incompatible_activity_types(values, callbacks) do
    callbacks
    |> Keyword.fetch!(:normalize_incompatible_activity_types)
    |> then(& &1.(values))
  end

  defp degradation_incompatible_activity_types(state, callbacks) do
    callbacks
    |> Keyword.fetch!(:degradation_incompatible_activity_types)
    |> then(& &1.(state))
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      degradation_incompatible_activity_types: &degradation_incompatible_activity_types/1,
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3,
      normalize_incompatible_activity_types:
        &BranchOperationalFeedback.normalize_incompatible_activity_types/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      truthy?: &ScalarValues.truthy?/1
    ]
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key) do
    OperationalFeedbackSourceMetadata.feedback_event_trust_boundary(
      trust_boundary,
      field,
      key,
      []
    )
  end

  defp degradation_incompatible_activity_types(state) do
    explicit =
      Map.get(state, "incompatible_activity_types") ||
        Map.get(state, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        BranchOperationalFeedback.normalize_incompatible_activity_types(explicit)

      Map.get(state, "spacecraft_available") == false or
          Map.get(state, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      Map.get(state, "payload_available") == false or Map.get(state, "antenna_available") == false ->
        []
        |> maybe_append_event(Map.get(state, "payload_available") == false, "observe")
        |> maybe_append_event(Map.get(state, "antenna_available") == false, "downlink")
        |> maybe_append_event(
          Map.get(state, "antenna_available") == false,
          "planned_contact"
        )
        |> Enum.reverse()

      true ->
        ["observe"]
    end
  end

  defp maybe_append_event(events, true, event), do: [event | events]
  defp maybe_append_event(events, false, _event), do: events
end
