defmodule OrbitalDynamics.CampaignPlanner.ScoreTermIdentifiers do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def entity_id(entity, keys), do: entity_id(entity, keys, callbacks())

  def entity_id(%{} = entity, keys, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    entity = stringify_keys.(entity)

    keys
    |> Enum.map(&Map.get(entity, &1))
    |> Enum.find(&stable_id_string?.(&1))
  end

  def entity_id(_entity, _keys, _callbacks), do: nil

  def target_ids(values), do: target_ids(values, callbacks())

  def target_ids(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &target_ids(&1, callbacks))
  end

  def target_ids(%{} = target, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    target = stringify_keys.(target)
    [Map.get(target, "target_id") || Map.get(target, "id")]
  end

  def target_ids(value, callbacks), do: [encode_value(value, callbacks)]

  def first_stable_activity_id(values), do: first_stable_activity_id(values, callbacks())

  def first_stable_activity_id(values, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    values
    |> Enum.flat_map(&activity_id_values(&1, callbacks))
    |> Enum.find(&stable_id_string?.(&1))
  end

  def activity_id_values(values), do: activity_id_values(values, callbacks())

  def activity_id_values(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &activity_id_values(&1, callbacks))
  end

  def activity_id_values(%{} = activity, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    activity = stringify_keys.(activity)

    [
      activity["activity_id"],
      activity["source_activity_id"],
      activity["observation_activity_id"],
      activity["contact_id"],
      activity["downlink_activity_id"],
      activity["id"]
    ]
  end

  def activity_id_values(value, callbacks), do: [encode_value(value, callbacks)]

  def source_activity_ids(row), do: source_activity_ids(row, callbacks())

  def source_activity_ids(row, callbacks) do
    [
      row["activity_ids"],
      row["activities"],
      row["source_activity_ids"],
      row["source_activity_id"],
      row["source_activity"],
      row["source_activities"],
      row["contact_ids"],
      row["contact_id"],
      row["contacts"],
      row["contact"],
      row["selected_contact_ids"],
      row["selected_contacts"],
      row["selected_contact"],
      row["observation_activity_ids"],
      row["observation_activity_id"],
      row["observations"],
      row["observation"],
      row["selected_observation_ids"],
      row["selected_observation_id"],
      row["selected_observations"],
      row["selected_observation"],
      row["candidate_observation_ids"],
      row["candidate_observation_id"],
      row["candidate_observations"],
      row["candidate_observation"],
      row["source_observation"],
      row["source_observations"],
      row["activity_id"]
    ]
    |> stable_activity_ids(callbacks)
  end

  def source_activity_id(row), do: source_activity_id(row, callbacks())

  def source_activity_id(row, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["source_activity_id"],
      row["observation_activity_id"],
      row["selected_observation_id"],
      row["candidate_observation_id"],
      row["activity_id"]
    ]
    |> Enum.find(&stable_id_string?.(&1)) ||
      first_stable_activity_id(
        [
          row["source_activity"],
          row["source_activities"],
          row["source_observation"],
          row["source_observations"],
          row["observation"],
          row["observations"],
          row["selected_observation"],
          row["selected_observations"],
          row["candidate_observation"],
          row["candidate_observations"],
          row["activity"],
          row["activities"]
        ],
        callbacks
      ) ||
      row
      |> source_activity_ids(callbacks)
      |> List.first()
  end

  def station_id(row), do: station_id(row, callbacks())

  def station_id(row, callbacks) do
    [
      row["ground_station_id"],
      row["station_id"],
      entity_id(row["ground_station"], ["ground_station_id", "station_id", "id"], callbacks),
      entity_id(row["station"], ["ground_station_id", "station_id", "id"], callbacks),
      observation_context_value(row, ["ground_station_id", "station_id"], callbacks),
      observation_context_entity_id(
        row,
        ["ground_station", "station"],
        ["ground_station_id", "station_id", "id"],
        callbacks
      )
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def scenario_id(row), do: scenario_id(row, callbacks())

  def scenario_id(row, callbacks) do
    [
      row["scenario_id"],
      observation_context_value(
        row,
        [
          "scenario_id",
          "spacecraft_id",
          "satellite_id"
        ],
        callbacks
      ),
      row["spacecraft_id"],
      row["satellite_id"]
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def spacecraft_id(row), do: spacecraft_id(row, callbacks())

  def spacecraft_id(row, callbacks) do
    [
      row["spacecraft_id"],
      observation_context_value(
        row,
        [
          "spacecraft_id",
          "satellite_id",
          "scenario_id"
        ],
        callbacks
      ),
      row["satellite_id"],
      row["scenario_id"]
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def primary_target_id(row), do: primary_target_id(row, callbacks())

  def primary_target_id(row, callbacks) do
    [
      row["target_id"],
      entity_id(row["target"], ["target_id", "id"], callbacks),
      observation_context_value(row, ["target_id", "id"], callbacks)
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def collection_id(row), do: collection_id(row, callbacks())

  def collection_id(row, callbacks) do
    [
      row["collection_id"],
      entity_id(row["collection"], ["collection_id", "id"], callbacks),
      pressure_collection_id(row, callbacks)
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def collection_ids(row), do: collection_ids(row, callbacks())

  def collection_ids(row, callbacks) do
    [
      row["collection_ids"],
      row["collections"],
      observation_context_value(row, ["collection_ids", "collections"], callbacks),
      collection_id(row, callbacks)
    ]
    |> stable_id_values(["collection_id", "id"], callbacks)
  end

  def product_id(row), do: product_id(row, callbacks())

  def product_id(row, callbacks) do
    [
      row["product_id"],
      row["data_product_id"],
      entity_id(row["product"], ["product_id", "data_product_id", "id"], callbacks),
      entity_id(row["data_product"], ["product_id", "data_product_id", "id"], callbacks),
      pressure_product_id(row, callbacks)
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def product_ids(row), do: product_ids(row, callbacks())

  def product_ids(row, callbacks) do
    row
    |> product_id_candidates(callbacks)
    |> Enum.flat_map(&product_id_values(&1, callbacks))
    |> Enum.filter(&stable_id_string?(&1, callbacks))
    |> Enum.uniq()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def payload_id(row), do: payload_id(row, callbacks())

  def payload_id(row, callbacks) do
    [
      row["payload_id"],
      entity_id(row["payload"], ["payload_id", "id"], callbacks),
      pressure_payload_id(row, callbacks)
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def payload_ids(row), do: payload_ids(row, callbacks())

  def payload_ids(row, callbacks) do
    [
      row["payload_ids"],
      row["payloads"],
      observation_context_value(row, ["payload_ids", "payloads"], callbacks),
      payload_id(row, callbacks)
    ]
    |> stable_id_values(["payload_id", "id"], callbacks)
  end

  def instrument_id(row), do: instrument_id(row, callbacks())

  def instrument_id(row, callbacks) do
    [
      row["instrument_id"],
      entity_id(row["instrument"], ["instrument_id", "id"], callbacks),
      pressure_instrument_id(row, callbacks)
    ]
    |> Enum.find(&stable_id_string?(&1, callbacks))
  end

  def instrument_ids(row), do: instrument_ids(row, callbacks())

  def instrument_ids(row, callbacks) do
    [
      row["instrument_ids"],
      row["instruments"],
      observation_context_value(row, ["instrument_ids", "instruments"], callbacks),
      instrument_id(row, callbacks)
    ]
    |> stable_id_values(["instrument_id", "id"], callbacks)
  end

  def product_id_values(values), do: product_id_values(values, callbacks())

  def product_id_values(values, callbacks) when is_list(values) do
    Enum.flat_map(values, &product_id_values(&1, callbacks))
  end

  def product_id_values(%{} = product, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    product = stringify_keys.(product)
    [product["product_id"] || product["data_product_id"] || product["id"]]
  end

  def product_id_values(value, callbacks), do: [encode_value(value, callbacks)]

  def stable_id_values(values, keys), do: stable_id_values(values, keys, callbacks())

  def stable_id_values(values, keys, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    values
    |> Enum.flat_map(&stable_id_values_from_value(&1, keys, callbacks))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def stable_id_values_from_value(values, keys),
    do: stable_id_values_from_value(values, keys, callbacks())

  def stable_id_values_from_value(values, keys, callbacks) when is_list(values) do
    Enum.flat_map(values, &stable_id_values_from_value(&1, keys, callbacks))
  end

  def stable_id_values_from_value(%{} = entity, keys, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    entity = stringify_keys.(entity)
    Enum.map(keys, &Map.get(entity, &1))
  end

  def stable_id_values_from_value(value, _keys, callbacks), do: [encode_value(value, callbacks)]

  defp stable_activity_ids(values, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    values
    |> Enum.flat_map(&activity_id_values(&1, callbacks))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp product_id_candidates(row, callbacks) do
    [
      row["product_ids"],
      row["data_product_ids"],
      row["products"],
      row["data_products"],
      observation_context_value(
        row,
        ["product_ids", "data_product_ids", "products", "data_products"],
        callbacks
      ),
      product_id(row, callbacks)
    ]
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      encode_value: &ValueEncoding.encode_value/1,
      observation_context_value: &observation_context_value/2,
      observation_context_entity_id: &observation_context_entity_id/3,
      pressure_collection_id: &pressure_collection_id/1,
      pressure_product_id: &pressure_product_id/1,
      pressure_payload_id: &pressure_payload_id/1,
      pressure_instrument_id: &pressure_instrument_id/1
    ]
  end

  defp objective_pressure_context_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      entity_id: &entity_id/2,
      target_ids: &target_ids/1
    ]
  end

  defp observation_context_value(row, fields) do
    ObjectivePressureContexts.observation_context_value(
      row,
      fields,
      objective_pressure_context_callbacks()
    )
  end

  defp observation_context_entity_id(row, fields, entity_keys) do
    ObjectivePressureContexts.observation_context_entity_id(
      row,
      fields,
      entity_keys,
      objective_pressure_context_callbacks()
    )
  end

  defp pressure_collection_id(row) do
    [
      row["collection_id"],
      objective_pressure_entity_id(row["collection"], ["collection_id", "id"]),
      observation_context_value(row, ["collection_id"])
    ]
    |> Enum.find(&ScalarValues.stable_id_string?/1)
  end

  defp pressure_product_id(row) do
    [
      row["product_id"],
      row["data_product_id"],
      objective_pressure_entity_id(row["product"], ["product_id", "data_product_id", "id"]),
      objective_pressure_entity_id(row["data_product"], ["product_id", "data_product_id", "id"]),
      observation_context_value(row, ["product_id", "data_product_id"])
    ]
    |> Enum.find(&ScalarValues.stable_id_string?/1)
  end

  defp pressure_payload_id(row) do
    [
      row["payload_id"],
      objective_pressure_entity_id(row["payload"], ["payload_id", "id"]),
      observation_context_value(row, ["payload_id"])
    ]
    |> Enum.find(&ScalarValues.stable_id_string?/1)
  end

  defp pressure_instrument_id(row) do
    [
      row["instrument_id"],
      objective_pressure_entity_id(row["instrument"], ["instrument_id", "id"]),
      observation_context_value(row, ["instrument_id"])
    ]
    |> Enum.find(&ScalarValues.stable_id_string?/1)
  end

  defp objective_pressure_entity_id(%{} = entity, keys), do: entity_id(entity, keys)
  defp objective_pressure_entity_id(value, _keys), do: ValueEncoding.encode_value(value)

  defp observation_context_value(row, fields, callbacks) do
    callbacks
    |> Keyword.fetch!(:observation_context_value)
    |> then(& &1.(row, fields))
  end

  defp observation_context_entity_id(row, fields, entity_keys, callbacks) do
    callbacks
    |> Keyword.fetch!(:observation_context_entity_id)
    |> then(& &1.(row, fields, entity_keys))
  end

  defp pressure_collection_id(row, callbacks) do
    callbacks
    |> Keyword.fetch!(:pressure_collection_id)
    |> then(& &1.(row))
  end

  defp pressure_product_id(row, callbacks) do
    callbacks
    |> Keyword.fetch!(:pressure_product_id)
    |> then(& &1.(row))
  end

  defp pressure_payload_id(row, callbacks) do
    callbacks
    |> Keyword.fetch!(:pressure_payload_id)
    |> then(& &1.(row))
  end

  defp pressure_instrument_id(row, callbacks) do
    callbacks
    |> Keyword.fetch!(:pressure_instrument_id)
    |> then(& &1.(row))
  end

  defp stable_id_string?(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:stable_id_string?)
    |> then(& &1.(value))
  end

  defp encode_value(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:encode_value)
    |> then(& &1.(value))
  end
end
