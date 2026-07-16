defmodule OrbitalDynamics.CampaignPlanner.ConstraintPressureContext do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def contact_downlink_field_values(row, fields),
    do: contact_downlink_field_values(row, fields, callbacks())

  def contact_downlink_field_values(row, fields, callbacks) do
    [
      row["selected_contact"],
      row["selected_contacts"],
      row["source_contact"],
      row["source_contacts"],
      row["contact"],
      row["contacts"]
    ]
    |> Enum.flat_map(&contact_downlink_values(&1, fields, callbacks))
  end

  def source_activity_ids(row), do: source_activity_ids(row, callbacks())

  def source_activity_ids(row, callbacks) do
    [
      row["activity_id"],
      row["activity_ids"],
      row["source_activity_id"],
      row["source_activity_ids"],
      row["selected_contact_id"],
      row["selected_contact_ids"],
      row["selected_contact"],
      row["selected_contacts"],
      row["source_contact_id"],
      row["source_contact_ids"],
      row["source_contact"],
      row["source_contacts"],
      row["contact_id"],
      row["contact_ids"],
      row["contact"],
      row["contacts"]
    ]
    |> Enum.flat_map(&source_activity_id_values(&1, callbacks))
    |> Enum.filter(&stable_id_string?(&1, callbacks))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def scenario_id(row), do: scenario_id(row, callbacks())

  def scenario_id(row, callbacks) do
    [
      row["scenario_id"],
      row["spacecraft_id"],
      contact_downlink_field_values(
        row,
        [
          "scenario_id",
          "spacecraft_id",
          "satellite_id"
        ],
        callbacks
      )
    ]
    |> List.flatten()
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def contact_entity_ids(row, fields, entity_keys),
    do: contact_entity_ids(row, fields, entity_keys, callbacks())

  def contact_entity_ids(row, fields, entity_keys, callbacks) do
    [
      row["selected_contact"],
      row["selected_contacts"],
      row["source_contact"],
      row["source_contacts"],
      row["contact"],
      row["contacts"]
    ]
    |> Enum.flat_map(&contact_entity_id_values(&1, fields, entity_keys, callbacks))
  end

  def trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp contact_downlink_values(values, fields, callbacks) when is_list(values) do
    Enum.flat_map(values, &contact_downlink_values(&1, fields, callbacks))
  end

  defp contact_downlink_values(%{} = contact, fields, callbacks) do
    contact = stringify_keys(contact, callbacks)

    fields
    |> Enum.flat_map(fn field ->
      [
        contact[field],
        get_in(contact, ["throughput_model", field]),
        get_in(contact, ["activity_context", field])
      ]
    end)
  end

  defp contact_downlink_values(_contact, _fields, _callbacks), do: []

  defp source_activity_id_values(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &source_activity_id_values(&1, callbacks))
  end

  defp source_activity_id_values(%{} = entity, callbacks) do
    entity = stringify_keys(entity, callbacks)

    [
      entity["activity_id"],
      entity["source_activity_id"],
      entity["contact_id"],
      entity["id"]
    ]
  end

  defp source_activity_id_values(value, _callbacks), do: [value]

  defp contact_entity_id_values(values, fields, entity_keys, callbacks) when is_list(values) do
    Enum.flat_map(values, &contact_entity_id_values(&1, fields, entity_keys, callbacks))
  end

  defp contact_entity_id_values(%{} = contact, fields, entity_keys, callbacks) do
    contact = stringify_keys(contact, callbacks)

    fields
    |> Enum.flat_map(fn field ->
      [
        contact[field],
        get_in(contact, ["activity_context", field])
      ]
    end)
    |> Enum.map(&score_term_entity_id(&1, entity_keys, callbacks))
  end

  defp contact_entity_id_values(_contact, _fields, _entity_keys, _callbacks), do: []

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2
    ]
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp stringify_keys(value, callbacks), do: callback(callbacks, :stringify_keys, [value])

  defp stable_id_string?(value, callbacks),
    do: callback(callbacks, :stable_id_string?, [value])

  defp score_term_entity_id(value, fields, callbacks),
    do: callback(callbacks, :score_term_entity_id, [value, fields])
end
