defmodule OrbitalDynamics.Communications.StationCalendar.ReservationSummaryValues do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.Availability

  def status_counts(affected_reservations, provider_contention_groups) do
    affected_statuses =
      affected_reservations
      |> Enum.flat_map(fn row ->
        [
          Map.get(row, "station_reservation_status")
          | Map.get(row, "station_calendar_reservation_statuses", [])
        ]
      end)

    provider_statuses =
      Enum.flat_map(provider_contention_groups, &Map.get(&1, "reservation_statuses", []))

    (affected_statuses ++ provider_statuses)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def ids(affected_reservations, provider_contention_groups) do
    affected_ids =
      affected_reservations
      |> Enum.flat_map(fn row ->
        [
          Map.get(row, "station_reservation_id")
          | Map.get(row, "station_calendar_reservation_ids", [])
        ]
      end)

    provider_ids = Enum.flat_map(provider_contention_groups, &Map.get(&1, "reservation_ids", []))

    (affected_ids ++ provider_ids)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def ids_by_status(affected_reservations, provider_contention_groups) do
    affected_pairs =
      Enum.flat_map(affected_reservations, fn row ->
        id_value_pairs(
          List.wrap(row["station_reservation_id"]),
          List.wrap(row["station_reservation_status"])
        ) ++
          id_value_pairs(
            row["station_calendar_reservation_ids"],
            row["station_calendar_reservation_statuses"]
          )
      end)

    provider_pairs =
      Enum.flat_map(provider_contention_groups, fn group ->
        id_value_pairs(group["reservation_ids"], group["reservation_statuses"])
      end)

    id_pairs_to_map(affected_pairs ++ provider_pairs)
  end

  def ids_by_match_status(affected_reservations) do
    affected_reservations
    |> Enum.flat_map(fn row ->
      id_value_pairs(
        [row["station_reservation_id"] | List.wrap(row["station_calendar_reservation_ids"])],
        List.wrap(row["station_reservation_match_status"])
      )
    end)
    |> id_pairs_to_map()
  end

  def ids_for_row(row) do
    [
      row["station_reservation_id"],
      row["station_calendar_reservation_ids"],
      row["reservation_ids"]
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> compact_sorted_values()
  end

  def statuses_for_row(row) do
    [
      row["station_reservation_status"],
      row["station_calendar_reservation_statuses"],
      row["reservation_statuses"]
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.map(&Availability.normalize_status/1)
    |> compact_sorted_values()
  end

  def reserved_by_for_row(row) do
    [
      row["station_reserved_by"],
      row["station_calendar_reserved_by"],
      row["reserved_by"]
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> compact_sorted_values()
  end

  def hold_review_row?(row) do
    row
    |> statuses_for_row()
    |> Enum.any?(&hold_status?/1)
  end

  def expiration_values(row) do
    [
      row["station_reservation_expires_at_s"],
      row["station_calendar_reservation_expires_at_s"],
      row["reservation_expires_at_s"]
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.map(&Availability.numeric_or_nil/1)
    |> Enum.filter(&is_number/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def expiration_count(rows) do
    rows
    |> Enum.flat_map(&Map.get(&1, "reservation_expires_at_s", []))
    |> length()
  end

  def earliest_expiration(rows) do
    rows
    |> Enum.flat_map(&Map.get(&1, "reservation_expires_at_s", []))
    |> Enum.min(fn -> nil end)
  end

  def row_ids(rows) do
    rows
    |> Enum.flat_map(&Map.get(&1, "reservation_ids", []))
    |> sorted_values()
  end

  def ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "reservation_ids", []))
    |> Enum.reject(fn {key, _ids} -> is_nil(key) end)
    |> Map.new(fn {key, ids} -> {key, ids |> List.flatten() |> sorted_values()} end)
  end

  def ids_by_row_values(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get(field, [])
      |> List.wrap()
      |> Enum.map(&{&1, Map.get(row, "reservation_ids", [])})
    end)
    |> Enum.reject(fn {key, ids} -> is_nil(key) or ids == [] end)
    |> Enum.group_by(fn {key, _ids} -> key end, fn {_key, ids} -> ids end)
    |> Map.new(fn {key, ids} -> {key, ids |> List.flatten() |> sorted_values()} end)
  end

  def id_value_pairs(ids, values) do
    ids = List.wrap(ids) |> Enum.reject(&is_nil/1)
    values = List.wrap(values) |> Enum.reject(&is_nil/1)

    cond do
      ids == [] or values == [] ->
        []

      length(values) == 1 ->
        Enum.map(ids, &{List.first(values), &1})

      true ->
        Enum.zip(values, ids)
    end
  end

  def id_pairs_to_map(pairs) do
    pairs
    |> Enum.group_by(
      fn {value, _id} -> Availability.normalize_status(value) end,
      fn {_value, id} -> id end
    )
    |> Enum.reject(fn {value, ids} -> is_nil(value) or ids == [] end)
    |> Map.new(fn {value, ids} -> {value, compact_sorted_values(ids)} end)
  end

  defp hold_status?(status) do
    status = Availability.normalize_status(status) || ""

    status == "held" or String.contains?(status, "hold")
  end

  defp sorted_values(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_sorted_values(values) do
    values
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
