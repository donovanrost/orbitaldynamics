defmodule OrbitalDynamics.Communications.ContactIntent.Summary do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactIntent.CapacityEvidence

  def build(rows, config) do
    rows = Enum.map(rows, &Map.merge(CapacityEvidence.required_context(&1), &1))
    capacity_demand_rows = Enum.filter(rows, &is_number(&1["required_capacity_fraction"]))
    normalize_direction = Map.fetch!(config, :normalize_direction)
    contact_ids_by_direction = row_ids_by_direction(rows, "id", normalize_direction) || %{}

    capacity_pack_contact_ids_by_direction =
      row_ids_by_direction(capacity_demand_rows, "id", normalize_direction) || %{}

    required_capacity_fraction_by_direction =
      required_capacity_fraction_by_direction(capacity_demand_rows, normalize_direction) || %{}

    contact_ids_by_direction_and_station =
      row_ids_by_direction_and_field(
        rows,
        "ground_station_id",
        "id",
        normalize_direction
      ) || %{}

    capacity_pack_contact_ids_by_direction_and_station =
      row_ids_by_direction_and_field(
        capacity_demand_rows,
        "ground_station_id",
        "id",
        normalize_direction
      ) || %{}

    required_capacity_fraction_by_direction_and_station =
      required_capacity_fraction_by_direction_and_field(
        capacity_demand_rows,
        "ground_station_id",
        normalize_direction
      ) || %{}

    %{
      "schema_contract" => Map.fetch!(config, :summary_schema_contract),
      "model" => "artifact_only_contact_intent_summary",
      "model_limits" => Map.fetch!(config, :model_limits),
      "source_artifact_type" => Map.fetch!(config, :schema_contract),
      "contact_intent_count" => length(rows),
      "capacity_pack_required_contact_count" => length(capacity_demand_rows),
      "capacity_pack_required_capacity_fraction" =>
        required_capacity_fraction_total(capacity_demand_rows),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        required_capacity_fraction_by_field(capacity_demand_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        empty_map_to_nil(required_capacity_fraction_by_direction),
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id" =>
        empty_map_to_nil(required_capacity_fraction_by_direction_and_station),
      "required_capacity_fraction_source_counts" =>
        count_by(capacity_demand_rows, "required_capacity_fraction_source"),
      "required_capacity_fraction_contact_ids_by_source" =>
        row_ids_by_field(capacity_demand_rows, "required_capacity_fraction_source", "id"),
      "contact_ids_by_ground_station_id" => row_ids_by_field(rows, "ground_station_id", "id"),
      "contact_ids_by_direction" => empty_map_to_nil(contact_ids_by_direction),
      "contact_ids_by_direction_and_ground_station_id" =>
        empty_map_to_nil(contact_ids_by_direction_and_station),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        row_ids_by_field(capacity_demand_rows, "ground_station_id", "id"),
      "capacity_pack_contact_ids_by_direction" =>
        empty_map_to_nil(capacity_pack_contact_ids_by_direction),
      "capacity_pack_contact_ids_by_direction_and_ground_station_id" =>
        empty_map_to_nil(capacity_pack_contact_ids_by_direction_and_station),
      "ground_station_ids" => row_values(rows, "ground_station_id"),
      "directions" => row_values(rows, "direction"),
      "direction_counts" => direction_counts(contact_ids_by_direction),
      "direction_routing" =>
        direction_routing(
          contact_ids_by_direction,
          required_capacity_fraction_by_direction,
          capacity_pack_contact_ids_by_direction,
          contact_ids_by_direction_and_station,
          required_capacity_fraction_by_direction_and_station,
          capacity_pack_contact_ids_by_direction_and_station
        ),
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
          "source_artifact_type" => Map.fetch!(config, :schema_contract)
        }
        |> Map.merge(CapacityEvidence.assumptions())
    }
  end

  defp direction_counts(contact_ids_by_direction) do
    contact_ids_by_direction
    |> Enum.map(fn {direction, contact_ids} -> {direction, length(contact_ids || [])} end)
    |> Map.new()
  end

  defp direction_routing(
         contact_ids_by_direction,
         required_capacity_fraction_by_direction,
         capacity_pack_contact_ids_by_direction,
         contact_ids_by_direction_and_station,
         required_capacity_fraction_by_direction_and_station,
         capacity_pack_contact_ids_by_direction_and_station
       ) do
    [
      Map.keys(contact_ids_by_direction),
      Map.keys(required_capacity_fraction_by_direction),
      Map.keys(capacity_pack_contact_ids_by_direction),
      Map.keys(contact_ids_by_direction_and_station),
      Map.keys(required_capacity_fraction_by_direction_and_station),
      Map.keys(capacity_pack_contact_ids_by_direction_and_station)
    ]
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "contact_count" => length(Map.get(contact_ids_by_direction, direction, [])),
          "contact_ids" => Map.get(contact_ids_by_direction, direction, []),
          "capacity_pack_required_capacity_fraction" =>
            Map.get(required_capacity_fraction_by_direction, direction),
          "capacity_pack_contact_ids" =>
            Map.get(capacity_pack_contact_ids_by_direction, direction, []),
          "ground_station_ids" =>
            contact_ids_by_direction_and_station
            |> Map.get(direction, %{})
            |> Map.keys()
            |> Enum.sort(),
          "contact_ids_by_ground_station_id" =>
            Map.get(contact_ids_by_direction_and_station, direction, %{}),
          "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
            Map.get(required_capacity_fraction_by_direction_and_station, direction, %{}),
          "capacity_pack_contact_ids_by_ground_station_id" =>
            Map.get(capacity_pack_contact_ids_by_direction_and_station, direction, %{})
        }
        |> Enum.reject(fn
          {"capacity_pack_contact_ids", []} -> false
          {_key, value} when value in [nil, %{}, []] -> true
          _entry -> false
        end)
        |> Map.new()

      {direction, route}
    end)
  end

  defp required_capacity_fraction_by_direction_and_field(
         rows,
         field,
         normalize_direction
       ) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      direction = normalize_direction.(row["direction"])
      field_value = row[field]
      required_fraction = row["required_capacity_fraction"]

      if is_binary(direction) and is_binary(field_value) and is_number(required_fraction) do
        update_in(totals, [Access.key(direction, %{}), Access.key(field_value, 0)], fn total ->
          total + required_fraction
        end)
      else
        totals
      end
    end)
    |> empty_map_to_nil()
  end

  defp required_capacity_fraction_total(rows) do
    rows
    |> Enum.map(& &1["required_capacity_fraction"])
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp required_capacity_fraction_by_field(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      key = row[field]
      required_fraction = row["required_capacity_fraction"]

      if is_binary(key) and is_number(required_fraction) do
        Map.update(totals, key, required_fraction, &(&1 + required_fraction))
      else
        totals
      end
    end)
    |> empty_map_to_nil()
  end

  defp required_capacity_fraction_by_direction(rows, normalize_direction) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      direction = normalize_direction.(row["direction"])
      required_fraction = row["required_capacity_fraction"]

      if is_binary(direction) and is_number(required_fraction) do
        Map.update(totals, direction, required_fraction, &(&1 + required_fraction))
      else
        totals
      end
    end)
    |> empty_map_to_nil()
  end

  defp row_ids_by_field(rows, field, id_field) do
    rows
    |> Enum.reduce(%{}, fn row, groups ->
      key = row[field]
      id = row[id_field]

      if is_binary(key) and is_binary(id) do
        Map.update(groups, key, [id], &[id | &1])
      else
        groups
      end
    end)
    |> Map.new(fn {key, values} -> {key, Enum.sort(values)} end)
    |> empty_map_to_nil()
  end

  defp row_ids_by_direction(rows, id_field, normalize_direction) do
    rows
    |> Enum.reduce(%{}, fn row, groups ->
      direction = normalize_direction.(row["direction"])
      id = row[id_field]

      if is_binary(direction) and is_binary(id) do
        Map.update(groups, direction, [id], &[id | &1])
      else
        groups
      end
    end)
    |> Map.new(fn {key, values} -> {key, Enum.sort(values)} end)
    |> empty_map_to_nil()
  end

  defp row_ids_by_direction_and_field(rows, field, id_field, normalize_direction) do
    rows
    |> Enum.reduce(%{}, fn row, groups ->
      direction = normalize_direction.(row["direction"])
      field_value = row[field]
      id = row[id_field]

      if is_binary(direction) and is_binary(field_value) and is_binary(id) do
        update_in(groups, [Access.key(direction, %{}), Access.key(field_value, [])], &[id | &1])
      else
        groups
      end
    end)
    |> Map.new(fn {direction, field_groups} ->
      sorted_groups =
        Map.new(field_groups, fn {field_value, values} -> {field_value, Enum.sort(values)} end)

      {direction, sorted_groups}
    end)
    |> empty_map_to_nil()
  end

  defp count_by(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, counts ->
      case row[field] do
        value when is_binary(value) -> Map.update(counts, value, 1, &(&1 + 1))
        _value -> counts
      end
    end)
    |> empty_map_to_nil()
  end

  defp row_values(rows, field) do
    rows
    |> Enum.map(& &1[field])
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp empty_map_to_nil(values) when values == %{}, do: nil
  defp empty_map_to_nil(values), do: values
end
