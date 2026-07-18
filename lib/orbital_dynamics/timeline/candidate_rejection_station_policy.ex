defmodule OrbitalDynamics.Timeline.CandidateRejectionStationPolicy do
  @moduledoc false

  @candidate_rejection_station_capacity_fraction_fields ~w(
    capacity_fraction
    station_capacity_fraction
    capacity_pack_capacity_fraction
  )

  def capacity_fraction_fields,
    do: @candidate_rejection_station_capacity_fraction_fields

  def station_unavailable?(activity) do
    status =
      activity
      |> candidate_rejection_station_status([
        "station_availability",
        "station_calendar_status",
        "availability",
        "status"
      ])
      |> normalized_token()

    status in ["unavailable", "not_available", "closed", "outage"]
  end

  def station_reserved?(activity) do
    status =
      activity
      |> candidate_rejection_station_status([
        "station_availability",
        "station_reservation_match_status",
        "station_calendar_status",
        "availability",
        "status",
        "reservation_status"
      ])
      |> normalized_token()

    status in ["reserved", "reservation_hold", "hold", "held", "matched_reserved"]
  end

  def station_capacity_reduced?(activity) do
    status =
      activity
      |> candidate_rejection_station_status([
        "station_availability",
        "station_calendar_status",
        "availability",
        "status"
      ])
      |> normalized_token()

    capacity_fraction = candidate_rejection_station_capacity_fraction(activity)

    status in ["reduced_capacity", "degraded_capacity"] or
      (is_number(capacity_fraction) and capacity_fraction >= 0.0 and capacity_fraction < 1.0)
  end

  defp candidate_rejection_station_status(activity, fields) do
    first_scalar_string(activity, fields) ||
      source_station_status(activity["source_station_calendar_entry"], fields) ||
      source_station_status(activity["source_station_calendar_overlaps"], fields)
  end

  defp source_station_status(sources, fields) when is_list(sources),
    do: Enum.find_value(sources, &source_station_status(&1, fields))

  defp source_station_status(%{} = source, fields), do: first_scalar_string(source, fields)

  defp source_station_status(_source, _fields), do: nil

  defp candidate_rejection_station_capacity_fraction(activity) do
    first_number(activity, @candidate_rejection_station_capacity_fraction_fields) ||
      source_station_capacity_fraction(activity["source_station_calendar_entry"]) ||
      source_station_capacity_fraction(activity["source_station_calendar_overlaps"])
  end

  defp source_station_capacity_fraction(sources) when is_list(sources),
    do: Enum.find_value(sources, &source_station_capacity_fraction/1)

  defp source_station_capacity_fraction(%{} = source),
    do: first_number(source, @candidate_rejection_station_capacity_fraction_fields)

  defp source_station_capacity_fraction(_source), do: nil

  defp first_scalar_string(activity, fields) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, fields)
  end

  defp first_number(activity, fields) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      fields,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp normalized_token(nil), do: nil

  defp normalized_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end
end
