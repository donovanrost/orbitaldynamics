defmodule OrbitalDynamics.Schema.StationCalendarProviderContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

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

  def validate(issues, path, provider) do
    issues
    |> validate_stable_ids(path, provider, ["id", "provider_id"])
    |> expect_equal(path, provider, "schema_contract", "station_calendar_provider.v1")
    |> expect_type(path, provider, "entries", :list)
    |> expect_optional_type(path, provider, "provenance", :map)
    |> expect_optional_type(path, provider, "assumptions", :map)
    |> require_trust_boundary(path, provider)
    |> validate_rows(
      path <> ".entries",
      Map.get(provider, "entries", []),
      fn acc, row_path, row ->
        validate_entry(acc, row_path, row)
      end
    )
    |> validate_entry_id_uniqueness(path, provider)
  end

  def validate_entry(issues, path, entry) do
    issues
    |> require_station(path, entry)
    |> require_availability(path, entry)
    |> validate_stable_ids(path, entry, ["id", "ground_station_id", "station_id"])
    |> expect_optional_one_of(path, entry, "availability", @availability_values)
    |> expect_optional_one_of(path, entry, "status", @availability_values)
    |> expect_optional_number(path, entry, "capacity_fraction")
    |> validate_stable_ids(path, entry, [
      "reservation_id",
      "reservation_hold_id",
      "hold_id"
    ])
    |> expect_optional_number(path, entry, "reservation_expires_at_s")
    |> expect_optional_number(path, entry, "reservation_hold_expires_at_s")
    |> expect_optional_number(path, entry, "hold_expires_at_s")
    |> expect_optional_number(path, entry, "expires_at_s")
    |> expect_optional_number(path, entry, "expires_at")
    |> expect_optional_number(path, entry, "valid_until_s")
    |> expect_optional_type(path, entry, "reserved_by", :binary)
    |> expect_optional_type(path, entry, "held_by", :binary)
    |> expect_optional_type(path, entry, "hold_owner", :binary)
    |> expect_optional_type(path, entry, "reservation_status", :binary)
    |> expect_optional_type(path, entry, "hold_status", :binary)
    |> validate_stable_ids(path, entry, [
      "provider_counteroffer_id",
      "counteroffer_id",
      "offer_id"
    ])
    |> expect_optional_type(path, entry, "provider_counteroffer_status", :binary)
    |> expect_optional_type(path, entry, "counteroffer_status", :binary)
    |> expect_optional_type(path, entry, "offer_status", :binary)
    |> expect_optional_type(path, entry, "negotiation_status", :binary)
    |> expect_optional_type(path, entry, "provider_counteroffer_reason_code", :binary)
    |> expect_optional_type(path, entry, "counteroffer_reason_code", :binary)
    |> expect_optional_type(path, entry, "offer_reason_code", :binary)
    |> expect_optional_type(path, entry, "provider_reason_code", :binary)
    |> expect_optional_type(path, entry, "reason_code", :binary)
    |> expect_optional_number(path, entry, "provider_counteroffer_cost_delta")
    |> expect_optional_number(path, entry, "counteroffer_cost_delta")
    |> expect_optional_number(path, entry, "cost_delta")
    |> expect_optional_number(path, entry, "price_delta")
    |> expect_optional_number(path, entry, "provider_counteroffer_lock_deadline_s")
    |> expect_optional_number(path, entry, "counteroffer_lock_deadline_s")
    |> expect_optional_number(path, entry, "schedule_lock_deadline_s")
    |> expect_optional_number(path, entry, "lock_deadline_s")
    |> expect_optional_number(path, entry, "provider_counteroffer_starts_at_s")
    |> expect_optional_number(path, entry, "counteroffer_starts_at_s")
    |> expect_optional_number(path, entry, "counteroffer_start_s")
    |> expect_optional_number(path, entry, "offered_starts_at_s")
    |> expect_optional_number(path, entry, "offered_start_s")
    |> expect_optional_number(path, entry, "provider_counteroffer_ends_at_s")
    |> expect_optional_number(path, entry, "provider_counteroffer_start_delta_s")
    |> expect_optional_number(path, entry, "provider_counteroffer_end_delta_s")
    |> expect_optional_number(path, entry, "provider_counteroffer_duration_delta_s")
    |> expect_optional_number(path, entry, "counteroffer_ends_at_s")
    |> expect_optional_number(path, entry, "counteroffer_end_s")
    |> expect_optional_number(path, entry, "offered_ends_at_s")
    |> expect_optional_number(path, entry, "offered_end_s")
    |> expect_optional_type(path, entry, "direction", :binary)
    |> expect_optional_type(path, entry, "directions", :list)
    |> validate_string_list_items(path, entry, "directions")
    |> expect_optional_type(path, entry, "station_calendar_directions", :list)
    |> validate_string_list_items(path, entry, "station_calendar_directions")
    |> expect_optional_type(path, entry, "trust_boundary", :binary)
    |> expect_optional_type(path, entry, "provenance", :map)
    |> expect_optional_number(path, entry, "starts_at_s")
    |> expect_optional_number(path, entry, "ends_at_s")
    |> expect_optional_number(path, entry, "start_s")
    |> expect_optional_number(path, entry, "end_s")
    |> validate_interval(path, entry)
  end

  defp validate_entry_id_uniqueness(issues, path, provider) do
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

    reject_duplicate_ids(issues, path <> ".entries", entry_ids)
  end

  defp require_trust_boundary(issues, path, provider) do
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
            path <> ".trust_boundary",
            "station_calendar_provider.v1 requires trust_boundary or provenance.trust_boundary"
          )
          | issues
        ]
    end
  end

  defp require_station(issues, path, entry) do
    if Map.get(entry, "ground_station_id") in [nil, ""] and
         Map.get(entry, "station_id") in [nil, ""] do
      [
        error(
          path <> ".ground_station_id",
          "ground_station_id or station_id is required"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp require_availability(issues, path, entry) do
    if Map.get(entry, "availability") in [nil, ""] and Map.get(entry, "status") in [nil, ""] do
      [error(path <> ".availability", "availability or status is required") | issues]
    else
      issues
    end
  end

  defp validate_interval(issues, path, entry) do
    starts_at_s = Map.get(entry, "starts_at_s") || Map.get(entry, "start_s")
    ends_at_s = Map.get(entry, "ends_at_s") || Map.get(entry, "end_s")

    cond do
      is_nil(starts_at_s) or is_nil(ends_at_s) ->
        issues

      is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s > starts_at_s ->
        issues

      is_number(starts_at_s) and is_number(ends_at_s) ->
        [error(path <> ".ends_at_s", "must be greater than starts_at_s") | issues]

      true ->
        issues
    end
  end

  defp reject_duplicate_ids(issues, path, ids) do
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
        error(path, "must not contain duplicate IDs: #{inspect(duplicate_ids)}")
        | issues
      ]
    end
  end

  defp error(path, message),
    do: %{"severity" => "error", "path" => path, "message" => message}
end
