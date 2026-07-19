defmodule OrbitalDynamics.Communications.LinkCapacity.StationAvailability do
  @moduledoc false

  alias OrbitalDynamics.Communications.LinkCapacity.ContactNormalization
  alias OrbitalDynamics.Communications.LinkCapacity.StationCapacity

  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }

  def unavailable_aliases, do: @unavailable_aliases
  def precedence, do: @station_availability_severity

  def value(contacts) when is_list(contacts) do
    contacts
    |> Enum.map(&contact_value/1)
    |> Enum.reject(&is_nil/1)
    |> highest_station_availability()
  end

  def value(%{} = row) do
    availability =
      row
      |> station_availability_candidates()
      |> Enum.map(&normalize_status/1)
      |> Enum.filter(&station_availability_value?/1)
      |> highest_station_availability()

    cond do
      availability in ["unavailable", "maintenance"] ->
        "unavailable"

      availability == "reserved" ->
        "reserved"

      availability == "reduced_capacity" ->
        "reduced_capacity"

      is_number(row["capacity_fraction_min"]) and row["capacity_fraction_min"] < 1.0 ->
        "reduced_capacity"

      true ->
        nil
    end
  end

  def value(_row), do: nil

  def contact_value(contact) do
    availability =
      contact
      |> station_availability_candidates()
      |> Enum.filter(&station_availability_value?/1)
      |> highest_station_availability()

    cond do
      availability in ["unavailable", "maintenance" | @unavailable_aliases] -> "unavailable"
      availability == "reserved" -> "reserved"
      availability == "reduced_capacity" -> "reduced_capacity"
      capacity_fraction_value(contact) < 1.0 -> "reduced_capacity"
      true -> nil
    end
  end

  defp station_availability_candidates(contact) do
    [
      contact["station_availability"],
      contact["availability"],
      contact["station_calendar_status"],
      contact["status"]
    ] ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_overlaps"])
  end

  defp highest_station_availability([]), do: nil

  defp highest_station_availability(values),
    do: Enum.max_by(values, &station_availability_severity/1)

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(value) when value in @unavailable_aliases, do: true
  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value) when value in @unavailable_aliases,
    do: @station_availability_severity["unavailable"]

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  defp capacity_fraction_value(contact), do: StationCapacity.value(contact)

  defp normalize_status(value),
    do: ContactNormalization.normalized_status_token(value, @unavailable_aliases)
end
