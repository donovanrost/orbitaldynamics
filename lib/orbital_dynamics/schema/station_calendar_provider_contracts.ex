defmodule OrbitalDynamics.Schema.StationCalendarProviderContracts do
  @moduledoc false

  @availability_values [
    "available",
    "unavailable",
    "outage",
    "down",
    "offline",
    "reduced_capacity",
    "maintenance",
    "reserved",
    "hold",
    "held",
    "on_hold",
    "onhold",
    "reservation_held",
    "reserved_hold",
    "reservation_hold"
  ]

  def validate(issues, path, provider, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, provider, ["id", "provider_id"])
    |> expect_equal(callbacks, path, provider, "schema_contract", "station_calendar_provider.v1")
    |> expect_type(callbacks, path, provider, "entries", :list)
    |> expect_optional_type(callbacks, path, provider, "provenance", :map)
    |> expect_optional_type(callbacks, path, provider, "assumptions", :map)
    |> require_trust_boundary(callbacks, path, provider)
    |> validate_rows(
      callbacks,
      path <> ".entries",
      Map.get(provider, "entries", []),
      fn acc, row_path, row ->
        validate_entry(acc, row_path, row, callbacks)
      end
    )
    |> validate_entry_id_uniqueness(callbacks, path, provider)
  end

  def validate_entry(issues, path, entry, callbacks) when is_list(callbacks) do
    issues
    |> require_station(callbacks, path, entry)
    |> require_availability(callbacks, path, entry)
    |> validate_stable_ids(callbacks, path, entry, ["id", "ground_station_id", "station_id"])
    |> expect_optional_one_of(callbacks, path, entry, "availability", @availability_values)
    |> expect_optional_one_of(callbacks, path, entry, "status", @availability_values)
    |> expect_optional_number(callbacks, path, entry, "capacity_fraction")
    |> validate_stable_ids(callbacks, path, entry, [
      "reservation_id",
      "reservation_hold_id",
      "hold_id"
    ])
    |> expect_optional_number(callbacks, path, entry, "reservation_expires_at_s")
    |> expect_optional_number(callbacks, path, entry, "reservation_hold_expires_at_s")
    |> expect_optional_number(callbacks, path, entry, "hold_expires_at_s")
    |> expect_optional_number(callbacks, path, entry, "expires_at_s")
    |> expect_optional_number(callbacks, path, entry, "expires_at")
    |> expect_optional_number(callbacks, path, entry, "valid_until_s")
    |> expect_optional_type(callbacks, path, entry, "reserved_by", :binary)
    |> expect_optional_type(callbacks, path, entry, "held_by", :binary)
    |> expect_optional_type(callbacks, path, entry, "hold_owner", :binary)
    |> expect_optional_type(callbacks, path, entry, "reservation_status", :binary)
    |> expect_optional_type(callbacks, path, entry, "hold_status", :binary)
    |> validate_stable_ids(callbacks, path, entry, [
      "provider_counteroffer_id",
      "counteroffer_id",
      "offer_id"
    ])
    |> expect_optional_type(callbacks, path, entry, "provider_counteroffer_status", :binary)
    |> expect_optional_type(callbacks, path, entry, "counteroffer_status", :binary)
    |> expect_optional_type(callbacks, path, entry, "offer_status", :binary)
    |> expect_optional_type(callbacks, path, entry, "negotiation_status", :binary)
    |> expect_optional_type(callbacks, path, entry, "provider_counteroffer_reason_code", :binary)
    |> expect_optional_type(callbacks, path, entry, "counteroffer_reason_code", :binary)
    |> expect_optional_type(callbacks, path, entry, "offer_reason_code", :binary)
    |> expect_optional_type(callbacks, path, entry, "provider_reason_code", :binary)
    |> expect_optional_type(callbacks, path, entry, "reason_code", :binary)
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_cost_delta")
    |> expect_optional_number(callbacks, path, entry, "counteroffer_cost_delta")
    |> expect_optional_number(callbacks, path, entry, "cost_delta")
    |> expect_optional_number(callbacks, path, entry, "price_delta")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(callbacks, path, entry, "counteroffer_lock_deadline_s")
    |> expect_optional_number(callbacks, path, entry, "schedule_lock_deadline_s")
    |> expect_optional_number(callbacks, path, entry, "lock_deadline_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "counteroffer_starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "counteroffer_start_s")
    |> expect_optional_number(callbacks, path, entry, "offered_starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "offered_start_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(callbacks, path, entry, "provider_counteroffer_duration_delta_s")
    |> expect_optional_number(callbacks, path, entry, "counteroffer_ends_at_s")
    |> expect_optional_number(callbacks, path, entry, "counteroffer_end_s")
    |> expect_optional_number(callbacks, path, entry, "offered_ends_at_s")
    |> expect_optional_number(callbacks, path, entry, "offered_end_s")
    |> expect_optional_type(callbacks, path, entry, "direction", :binary)
    |> expect_optional_type(callbacks, path, entry, "directions", :list)
    |> validate_string_list_items(callbacks, path, entry, "directions")
    |> expect_optional_type(callbacks, path, entry, "station_calendar_directions", :list)
    |> validate_string_list_items(callbacks, path, entry, "station_calendar_directions")
    |> expect_optional_type(callbacks, path, entry, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, entry, "provenance", :map)
    |> expect_optional_number(callbacks, path, entry, "starts_at_s")
    |> expect_optional_number(callbacks, path, entry, "ends_at_s")
    |> expect_optional_number(callbacks, path, entry, "start_s")
    |> expect_optional_number(callbacks, path, entry, "end_s")
    |> validate_interval(callbacks, path, entry)
  end

  defp validate_entry_id_uniqueness(issues, callbacks, path, provider) do
    entry_ids =
      provider
      |> Map.get("entries", [])
      |> case do
        entries when is_list(entries) -> entries
        _entries -> []
      end
      |> Enum.filter(&is_map/1)
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.reject(&(&1 in [nil, ""]))

    reject_duplicate_ids(issues, callbacks, path <> ".entries", entry_ids)
  end

  defp require_trust_boundary(issues, callbacks, path, provider) do
    trust_boundary = Map.get(provider, "trust_boundary")
    provenance_trust_boundary = get_in(provider, ["provenance", "trust_boundary"])

    cond do
      is_binary(trust_boundary) and trust_boundary != "" ->
        issues

      is_binary(provenance_trust_boundary) and provenance_trust_boundary != "" ->
        issues

      true ->
        [
          error(
            callbacks,
            path <> ".trust_boundary",
            "station_calendar_provider.v1 requires trust_boundary or provenance.trust_boundary"
          )
          | issues
        ]
    end
  end

  defp require_station(issues, callbacks, path, entry) do
    if Map.get(entry, "ground_station_id") in [nil, ""] and
         Map.get(entry, "station_id") in [nil, ""] do
      [
        error(
          callbacks,
          path <> ".ground_station_id",
          "ground_station_id or station_id is required"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp require_availability(issues, callbacks, path, entry) do
    if Map.get(entry, "availability") in [nil, ""] and Map.get(entry, "status") in [nil, ""] do
      [error(callbacks, path <> ".availability", "availability or status is required") | issues]
    else
      issues
    end
  end

  defp validate_interval(issues, callbacks, path, entry) do
    starts_at_s = Map.get(entry, "starts_at_s") || Map.get(entry, "start_s")
    ends_at_s = Map.get(entry, "ends_at_s") || Map.get(entry, "end_s")

    cond do
      is_nil(starts_at_s) or is_nil(ends_at_s) ->
        issues

      is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s > starts_at_s ->
        issues

      is_number(starts_at_s) and is_number(ends_at_s) ->
        [error(callbacks, path <> ".ends_at_s", "must be greater than starts_at_s") | issues]

      true ->
        issues
    end
  end

  defp reject_duplicate_ids(issues, callbacks, path, ids) do
    duplicate_ids =
      ids
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> id end)
      |> Enum.sort()

    if duplicate_ids == [] do
      issues
    else
      [
        error(callbacks, path, "must not contain duplicate IDs: #{inspect(duplicate_ids)}")
        | issues
      ]
    end
  end

  defp expect_equal(issues, callbacks, path, map, field, expected) do
    callback!(callbacks, :expect_equal).(issues, path, map, field, expected)
  end

  defp expect_optional_number(issues, callbacks, path, map, field) do
    callback!(callbacks, :expect_optional_number).(issues, path, map, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, map, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, map, field, values)
  end

  defp expect_optional_type(issues, callbacks, path, map, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, map, field, type)
  end

  defp expect_type(issues, callbacks, path, map, field, type) do
    callback!(callbacks, :expect_type).(issues, path, map, field, type)
  end

  defp validate_rows(issues, callbacks, path, rows, validator) do
    callback!(callbacks, :validate_rows).(issues, path, rows, validator)
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, map, fields)
  end

  defp validate_string_list_items(issues, callbacks, path, map, field) do
    callback!(callbacks, :validate_string_list_items).(issues, path, map, field)
  end

  defp error(callbacks, path, message) do
    callback!(callbacks, :error).(path, message)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
