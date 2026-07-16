defmodule OrbitalDynamics.CampaignPlanner.DownlinkObjectiveRequirements do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    DownlinkActivityNormalization,
    DownlinkCompletionCandidates,
    PriorActivityContext,
    ScalarValues,
    ValueEncoding
  }

  @objective_types ["downlink_completion", "required_downlink_completion"]

  def required_contacts(objective, prior_plan),
    do: required_contacts(objective, prior_plan, callbacks())

  def required_contacts(objective, prior_plan, callbacks) do
    case objective do
      %{"objectives" => _objectives} = mission_state ->
        case objectives(mission_state, callbacks) do
          [] ->
            max(1, planned_count(prior_plan, nil, callbacks))

          objectives ->
            objectives
            |> Enum.map(&required_contacts(&1, prior_plan, callbacks))
            |> Enum.sum()
        end

      %{} = objective ->
        case required_contact_count(objective, callbacks) do
          value when is_number(value) -> normalize_required_contact_count(value)
          _value -> max(1, planned_count(prior_plan, nil, callbacks))
        end

      _objective ->
        max(1, planned_count(prior_plan, nil, callbacks))
    end
  end

  def required_mb(objective), do: required_mb(objective, callbacks())

  def required_mb(%{} = objective, callbacks) do
    objective_number_from_fields = Keyword.fetch!(callbacks, :objective_number_from_fields)

    objective
    |> objective_number_from_fields.([
      "required_downlink_mb",
      "target_downlink_mb",
      "downlink_requirement_mb",
      "required_throughput_mb",
      "required_volume_mb",
      "required_data_volume_mb",
      "target_volume_mb",
      "target_data_volume_mb",
      "min_downlink_mb"
    ])
    |> case do
      value when is_number(value) -> max(value * 1.0, 0.0)
      _value -> nil
    end
  end

  def required_mb(_objective, _callbacks), do: nil

  def objectives(mission_state), do: objectives(mission_state, callbacks())

  def objectives(mission_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    mission_state
    |> Map.get("objectives", [])
    |> Enum.map(stringify_keys)
    |> Enum.filter(fn
      %{"type" => type} when type in @objective_types -> true
      _objective -> false
    end)
  end

  def objective?(mission_state) do
    mission_state
    |> Map.get("objectives", [])
    |> Enum.any?(fn
      %{"type" => type} when type in @objective_types -> true
      _objective -> false
    end)
  end

  def planned_count(prior_plan, objective), do: planned_count(prior_plan, objective, callbacks())

  def planned_count(prior_plan, objective, callbacks) do
    prior_plan_activities = Keyword.fetch!(callbacks, :prior_plan_activities)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    downlink_completion_event_match? =
      Keyword.fetch!(callbacks, :downlink_completion_event_match?)

    prior_plan
    |> prior_plan_activities.()
    |> Enum.map(stringify_keys)
    |> Enum.count(
      &(downlink_activity?.(&1) and downlink_completion_event_match?.(&1, objective || %{}))
    )
  end

  def planned_mb(prior_plan_or_activities, objective),
    do: planned_mb(prior_plan_or_activities, objective, callbacks())

  def planned_mb(prior_plan_or_activities, objective, callbacks) do
    prior_plan_activities = Keyword.fetch!(callbacks, :prior_plan_activities)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)
    downlink_activity_mb = Keyword.fetch!(callbacks, :downlink_activity_mb)

    downlink_completion_event_match? =
      Keyword.fetch!(callbacks, :downlink_completion_event_match?)

    prior_plan_or_activities
    |> prior_plan_activities.()
    |> Enum.map(stringify_keys)
    |> Enum.filter(
      &(downlink_activity?.(&1) and downlink_completion_event_match?.(&1, objective || %{}))
    )
    |> Enum.map(downlink_activity_mb)
    |> Enum.sum()
  end

  defp required_contact_count(objective, callbacks) do
    objective_number_from_fields = Keyword.fetch!(callbacks, :objective_number_from_fields)

    explicit =
      objective
      |> objective_number_from_fields.([
        "required_contacts",
        "required_contact_count",
        "expected_contact_count",
        "required_downlink_contacts",
        "required_downlink_contact_count",
        "target_contact_count",
        "target_downlink_contact_count",
        "min_contact_count",
        "minimum_contact_count"
      ])

    cond do
      is_number(explicit) ->
        explicit

      contact_count = required_contact_identity_count(objective, callbacks) ->
        contact_count

      true ->
        nil
    end
  end

  defp required_contact_identity_count(objective, callbacks) do
    [
      objective["required_downlink_contact_ids"],
      objective["required_downlink_contact_id"],
      objective["required_contact_ids"],
      objective["required_contact_id"],
      objective["expected_contact_ids"],
      objective["expected_contact_id"],
      objective["contacts"],
      objective["downlink_contacts"]
    ]
    |> Enum.flat_map(&required_contact_identities(&1, callbacks))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> nil
      contacts -> length(contacts)
    end
  end

  defp required_contact_identities(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &required_contact_identities(&1, callbacks))
  end

  defp required_contact_identities(%{} = contact, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    contact = stringify_keys.(contact)

    [
      contact["contact_id"],
      contact["downlink_activity_id"],
      contact["activity_id"],
      contact["id"]
    ]
  end

  defp required_contact_identities(value, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    [encode_value.(value)]
  end

  defp normalize_required_contact_count(count) when is_number(count) do
    if count == trunc(count), do: trunc(count), else: count
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      encode_value: &ValueEncoding.encode_value/1,
      objective_number_from_fields: &objective_number_from_fields/2,
      prior_plan_activities: &PriorActivityContext.activities/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      downlink_completion_event_match?: &DownlinkCompletionCandidates.event_match?/2,
      downlink_activity_mb: &downlink_activity_mb/1
    ]
  end

  defp objective_number_from_fields(objective, fields) do
    Enum.find_value(fields, fn field ->
      case ScalarValues.numeric_or_nil(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp downlink_activity_mb(activity) do
    activity_capacity =
      ScalarValues.numeric_or_nil(Map.get(activity, "capacity_adjusted_throughput_mb"))

    model_capacity =
      ScalarValues.numeric_or_nil(
        get_in(activity, ["throughput_model", "capacity_adjusted_throughput_mb"])
      )

    cond do
      is_number(activity_capacity) ->
        activity_capacity * 1.0

      is_number(model_capacity) ->
        model_capacity * 1.0

      true ->
        throughput_mb =
          ScalarValues.numeric_or_nil(Map.get(activity, "estimated_throughput_mb")) ||
            ScalarValues.numeric_or_nil(Map.get(activity, "planned_throughput_mb")) || 0.0

        station_capacity_fraction =
          ScalarValues.numeric_or_nil(
            get_in(activity, ["throughput_model", "station_capacity_fraction"])
          ) ||
            ScalarValues.numeric_or_nil(Map.get(activity, "station_capacity_fraction")) || 1.0

        throughput_mb * station_capacity_fraction
    end
  end
end
