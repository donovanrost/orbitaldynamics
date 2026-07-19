defmodule OrbitalDynamics.Communications.StationCalendar.Availability do
  @moduledoc false

  @values ["available", "unavailable", "reduced_capacity", "maintenance", "reserved"]
  @unavailable_aliases ["outage", "down", "offline"]
  @reservation_hold_aliases [
    "hold",
    "held",
    "on_hold",
    "onhold",
    "reservation_held",
    "reservation_hold",
    "reserved_hold"
  ]

  def values, do: @values
  def unavailable_aliases, do: @unavailable_aliases
  def reservation_hold_aliases, do: @reservation_hold_aliases

  def unavailable?(station) do
    availability =
      station
      |> Map.get("availability")
      |> encode_value()
      |> normalize_token()

    status =
      station
      |> Map.get("status", "available")
      |> encode_value()
      |> normalize_token()

    availability in ["unavailable", "maintenance" | @unavailable_aliases] or
      status in ["unavailable", "maintenance" | @unavailable_aliases] or
      Map.get(station, "available") == false
  end

  def capacity_fraction(station) do
    case Map.get(station, "capacity_pack_capacity_fraction") ||
           Map.get(station, "capacity_fraction") ||
           Map.get(station, "station_capacity_fraction") ||
           capacity_percent_fraction(station) || Map.get(station, "availability") do
      value when is_number(value) ->
        validate_capacity_fraction!(value)

      value when is_binary(value) ->
        value
        |> numeric_or_nil()
        |> capacity_fraction_or_full!()

      _value ->
        1.0
    end
  end

  def station_value(station) do
    raw_availability = station |> Map.get("availability") |> encode_value()

    availability = normalize_token(raw_availability)

    status =
      station
      |> Map.get("status", "available")
      |> encode_value()
      |> normalize_token()

    cond do
      availability in ["reserved", "unavailable", "reduced_capacity"] ->
        availability

      is_number(raw_availability) and capacity_fraction(station) < 1.0 ->
        "reduced_capacity"

      status == "reserved" ->
        "reserved"

      unavailable?(station) ->
        "unavailable"

      capacity_fraction(station) < 1.0 ->
        "reduced_capacity"

      true ->
        "available"
    end
  end

  def normalize(value, _capacity_fraction) when is_number(value) do
    if value < 1.0, do: "reduced_capacity", else: "available"
  end

  def normalize(value, capacity_fraction) do
    availability =
      value
      |> encode_value()
      |> normalize_token()

    cond do
      availability in @unavailable_aliases -> "unavailable"
      availability in @reservation_hold_aliases -> "reserved"
      availability in @values -> availability
      is_number(capacity_fraction) and capacity_fraction < 1.0 -> "reduced_capacity"
      true -> availability
    end
  end

  def default_reservation_status(raw_availability) do
    normalized = raw_availability |> encode_value() |> normalize_token()

    if normalized in @reservation_hold_aliases, do: "hold"
  end

  def normalize_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def normalize_token(value), do: value

  def normalize_status(nil), do: nil

  def normalize_status(value) do
    value
    |> encode_value()
    |> normalize_token()
  end

  def normalized_capacity_fraction(entry, raw_availability) do
    case Map.get(entry, "capacity_pack_capacity_fraction") || Map.get(entry, "capacity_fraction") ||
           Map.get(entry, "station_capacity_fraction") ||
           capacity_percent_fraction(entry) do
      value when is_number(value) ->
        value

      value when is_binary(value) ->
        numeric_or_nil(value)

      _value when is_number(raw_availability) ->
        raw_availability

      _value when is_binary(raw_availability) ->
        numeric_or_nil(raw_availability)

      _value ->
        nil
    end
  end

  def normalized_capacity_pack_capacity_fraction(entry) do
    case Map.get(entry, "capacity_pack_capacity_fraction") do
      value when is_number(value) -> value
      value when is_binary(value) -> numeric_or_nil(value)
      _value -> nil
    end
    |> validate_capacity_fraction!()
  end

  def validate_capacity_fraction!(nil), do: nil

  def validate_capacity_fraction!(value)
      when is_number(value) and value >= 0.0 and value <= 1.0,
      do: value

  def validate_capacity_fraction!(_value) do
    raise ArgumentError, "station calendar capacity_fraction must be between 0.0 and 1.0"
  end

  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  def numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

  defp capacity_percent_fraction(entry) do
    [
      Map.get(entry, "capacity_percent"),
      Map.get(entry, "station_capacity_percent")
    ]
    |> Enum.find_value(fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
        _value -> nil
      end
    end)
  end

  defp capacity_fraction_or_full!(value) when is_number(value),
    do: validate_capacity_fraction!(value)

  defp capacity_fraction_or_full!(_value), do: 1.0

  defp encode_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 6)

  defp encode_value(value), do: to_string(value)
end
