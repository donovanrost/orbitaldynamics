defmodule OrbitalDynamics.Communications.LinkCapacity.StationReservationEvidence do
  @moduledoc false

  alias OrbitalDynamics.Communications.LinkCapacity.{ContactIdentity, ContactNormalization}

  @unavailable_aliases ["outage", "down", "offline"]

  def row_ids(rows) do
    [
      row_list_values(rows, "station_reservation_ids", :stable_id),
      ids(rows)
    ]
    |> List.flatten()
    |> sorted_stable_ids()
    |> empty_list_to_nil()
  end

  def row_expires_at_s(rows) do
    [
      row_list_values(rows, "station_reservation_expires_at_s", :number),
      expires_at_s(rows)
    ]
    |> normalized_number_values()
  end

  def row_reserved_bys(rows) do
    [
      row_list_values(rows, "station_reserved_bys", :string),
      reserved_bys(rows)
    ]
    |> normalized_string_values()
  end

  def row_statuses(rows) do
    [
      row_list_values(rows, "station_reservation_statuses", :string),
      statuses(rows)
    ]
    |> normalized_status_values()
  end

  def row_match_status_counts(rows) do
    rows
    |> Enum.flat_map(&row_match_statuses/1)
    |> Enum.frequencies()
    |> empty_map_to_nil()
  end

  def row_match_statuses(row) do
    [
      row["station_reservation_match_status"],
      row["reservation_match_status"],
      row["station_reservation_match_statuses"],
      source_values(row["source_station_calendar_entry"], [
        "station_reservation_match_status",
        "reservation_match_status"
      ]),
      source_values(row["source_station_calendar_overlaps"], [
        "station_reservation_match_status",
        "reservation_match_status"
      ])
    ]
    |> normalized_status_values()
    |> List.wrap()
  end

  def ids(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_id"],
        contact["reservation_id"]
      ] ++
        source_reservation_ids(contact["source_station_calendar_entry"]) ++
        source_reservation_ids(contact["source_station_calendar_overlaps"])
    end)
    |> Enum.map(&ContactIdentity.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  def expires_at_s(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_expires_at_s"],
        contact["reservation_expires_at_s"],
        contact["reservation_hold_expires_at_s"],
        contact["hold_expires_at_s"],
        contact["expires_at_s"],
        contact["expires_at"],
        contact["station_calendar_reservation_expires_at_s"]
      ] ++
        source_number_values(contact["source_station_calendar_entry"], [
          "station_calendar_reservation_expires_at_s",
          "station_reservation_expires_at_s",
          "reservation_expires_at_s",
          "reservation_hold_expires_at_s",
          "hold_expires_at_s",
          "expires_at_s",
          "expires_at"
        ]) ++
        source_number_values(contact["source_station_calendar_overlaps"], [
          "station_calendar_reservation_expires_at_s",
          "station_reservation_expires_at_s",
          "reservation_expires_at_s",
          "reservation_hold_expires_at_s",
          "hold_expires_at_s",
          "expires_at_s",
          "expires_at"
        ])
    end)
    |> normalized_number_values()
  end

  def reserved_bys(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reserved_by"],
        contact["reserved_by"]
      ] ++
        source_values(contact["source_station_calendar_entry"], [
          "station_reserved_by",
          "reserved_by"
        ]) ++
        source_values(contact["source_station_calendar_overlaps"], [
          "station_reserved_by",
          "reserved_by"
        ])
    end)
    |> normalized_string_values()
  end

  def statuses(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_status"],
        contact["reservation_status"]
      ] ++
        source_values(contact["source_station_calendar_entry"], [
          "station_reservation_status",
          "reservation_status"
        ]) ++
        source_values(contact["source_station_calendar_overlaps"], [
          "station_reservation_status",
          "reservation_status"
        ])
    end)
    |> normalized_status_values()
  end

  def match_statuses(contacts) do
    contacts
    |> Enum.flat_map(fn contact ->
      [
        contact["station_reservation_match_status"],
        contact["reservation_match_status"]
      ] ++
        source_values(contact["source_station_calendar_entry"], [
          "station_reservation_match_status",
          "reservation_match_status"
        ]) ++
        source_values(contact["source_station_calendar_overlaps"], [
          "station_reservation_match_status",
          "reservation_match_status"
        ])
    end)
    |> normalized_status_values()
  end

  def source_values(sources, fields) when is_list(sources),
    do: Enum.flat_map(sources, &source_values(&1, fields))

  def source_values(%{} = source, fields),
    do: Enum.map(fields, &Map.get(source, &1))

  def source_values(_source, _fields), do: []

  def normalized_string_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  def normalized_number_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&ContactNormalization.numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp normalized_status_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&ContactNormalization.normalized_status_token(&1, @unavailable_aliases))
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp row_list_values(rows, field, :stable_id) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> Enum.map(&ContactIdentity.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp row_list_values(rows, field, :string) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> normalized_string_values()
  end

  defp row_list_values(rows, field, :number) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> normalized_number_values()
  end

  defp source_reservation_ids(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_reservation_ids/1)

  defp source_reservation_ids(%{} = source) do
    explicit_ids =
      source_values(source, ["station_reservation_id", "reservation_id"])
      |> Enum.reject(&is_nil/1)

    cond do
      explicit_ids != [] ->
        explicit_ids

      reserved_source?(source) ->
        source_values(source, [
          "id",
          "entry_id",
          "station_calendar_entry_id"
        ])

      true ->
        []
    end
  end

  defp source_reservation_ids(_source), do: []

  defp source_number_values(sources, fields),
    do: source_number_values(sources, fields, 0)

  defp source_number_values(sources, fields, depth) when is_list(sources),
    do: Enum.flat_map(sources, &source_number_values(&1, fields, depth))

  defp source_number_values(%{} = source, fields, depth) when depth < 4 do
    direct_values =
      fields
      |> Enum.flat_map(fn field -> List.wrap(Map.get(source, field)) end)

    direct_values ++
      source_number_values(
        source["source_station_calendar_entry"],
        fields,
        depth + 1
      ) ++
      source_number_values(
        source["source_station_calendar_overlaps"],
        fields,
        depth + 1
      )
  end

  defp source_number_values(_source, _fields, _depth), do: []

  defp reserved_source?(source) do
    source
    |> source_availability_candidates()
    |> Enum.any?(&(&1 == "reserved"))
  end

  defp source_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_availability_candidates/1)

  defp source_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_availability_candidates(_source), do: []

  defp sorted_stable_ids(values) do
    values
    |> Enum.map(&ContactIdentity.stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp string_value(value) when value in [nil, ""], do: nil

  defp string_value(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp string_value(value) when is_atom(value), do: value |> Atom.to_string() |> string_value()
  defp string_value(value) when is_integer(value), do: Integer.to_string(value)
  defp string_value(value), do: value |> to_string() |> string_value()

  defp empty_list_to_nil([]), do: nil
  defp empty_list_to_nil(values), do: values

  defp empty_map_to_nil(map) when map == %{}, do: nil
  defp empty_map_to_nil(map), do: map
end
