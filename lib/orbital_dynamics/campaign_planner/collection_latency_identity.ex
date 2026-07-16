defmodule OrbitalDynamics.CampaignPlanner.CollectionLatencyIdentity do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyMaps

  def observation_match?(activity, objective) do
    target_id = Map.get(objective, "target_id") || Map.get(objective, "id")
    scenario_id = Map.get(objective, "scenario_id")

    activity["type"] == "observe" and
      (is_nil(target_id) or activity["target_id"] == target_id) and
      (is_nil(scenario_id) or activity["scenario_id"] == scenario_id) and
      identity_match?(activity, objective)
  end

  defp identity_match?(activity, objective) do
    Enum.all?(
      [
        {collection_keys(), collection_keys()},
        {payload_keys(), payload_keys()},
        {instrument_keys(), instrument_keys()},
        {product_keys(), product_keys()}
      ],
      fn {objective_keys, activity_keys} ->
        objective_values = selector_values(objective, objective_keys)

        objective_values == [] or
          Enum.any?(
            selector_values(activity, activity_keys),
            &(&1 in objective_values)
          )
      end
    )
  end

  def selector_values(row, keys) when is_map(row) do
    keys
    |> Enum.flat_map(fn key ->
      selector_value(key, Map.get(row, key))
    end)
    |> Enum.map(&CollectionLatencyMaps.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def selector_values(_row, _keys), do: []

  def identity_value(objective, observation, field) do
    aliases = keys_for_field(field)

    objective_values = selector_values(objective, aliases)
    observation_values = selector_values(observation, aliases)

    cond do
      objective_values != [] and observation_values != [] ->
        Enum.find(observation_values, &(&1 in objective_values)) || List.first(objective_values)

      objective_values != [] ->
        List.first(objective_values)

      true ->
        List.first(observation_values)
    end
  end

  def objective_only_value(objective, field) do
    objective
    |> selector_values(keys_for_field(field))
    |> case do
      [value] -> value
      _values -> nil
    end
  end

  def objective_only_values(objective, field) do
    objective
    |> selector_values(keys_for_field(field))
    |> case do
      [] -> nil
      values -> values
    end
  end

  def product_ids(objective, observation) do
    values =
      [objective, observation]
      |> Enum.flat_map(&selector_values(&1, product_keys()))
      |> Enum.uniq()
      |> Enum.sort()

    if values == [], do: nil, else: values
  end

  def keys_for_field("collection_id"), do: collection_keys()
  def keys_for_field("product_id"), do: product_keys()
  def keys_for_field("payload_id"), do: payload_keys()
  def keys_for_field("instrument_id"), do: instrument_keys()

  def collection_keys, do: ["collection_id", "collection_ids", "collection", "collections"]

  def product_keys,
    do: [
      "product_id",
      "data_product_id",
      "product_ids",
      "data_product_ids",
      "product",
      "data_product",
      "products",
      "data_products"
    ]

  def payload_keys, do: ["payload_id", "payload_ids", "payload", "payloads"]

  def instrument_keys, do: ["instrument_id", "instrument_ids", "instrument", "instruments"]

  defp selector_value(_key, nil), do: []

  defp selector_value(key, values) when is_list(values) do
    Enum.flat_map(values, &selector_value(key, &1))
  end

  defp selector_value(key, %{} = value) do
    values =
      key
      |> CollectionLatencyMaps.encode_value()
      |> selector_nested_keys()
      |> Enum.flat_map(fn nested_key ->
        selector_value(nested_key, Map.get(value, nested_key))
      end)

    if values == [], do: selector_value("id", Map.get(value, "id")), else: values
  end

  defp selector_value(_key, value), do: [value]

  defp selector_nested_keys(key)
       when key in ["collection", "collections", "collection_id", "collection_ids"],
       do: ["collection_id", "id"]

  defp selector_nested_keys(key)
       when key in [
              "product",
              "products",
              "data_product",
              "data_products",
              "product_id",
              "product_ids",
              "data_product_id",
              "data_product_ids"
            ],
       do: ["product_id", "data_product_id", "id"]

  defp selector_nested_keys(key)
       when key in ["payload", "payloads", "payload_id", "payload_ids"],
       do: ["payload_id", "id"]

  defp selector_nested_keys(key)
       when key in ["instrument", "instruments", "instrument_id", "instrument_ids"],
       do: ["instrument_id", "id"]

  defp selector_nested_keys(_key), do: ["id"]
end
