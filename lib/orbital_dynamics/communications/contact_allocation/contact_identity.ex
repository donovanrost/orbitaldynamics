defmodule OrbitalDynamics.Communications.ContactAllocation.ContactIdentity do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def contact_id(contact) do
    case contact_id_or_nil(contact) do
      nil -> raise ArgumentError, "contact id is required"
      value -> value
    end
  end

  def contact_id_or_nil(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> stable_id_or_nil(value)
      value when is_atom(value) and not is_nil(value) -> stable_id_or_nil(value)
      value when is_integer(value) -> stable_id_or_nil(value)
      _value -> nil
    end
  end

  def contact_id_issue(contact) do
    raw_id =
      Map.get(contact, "id") || Map.get(contact, "contact_id") ||
        Map.get(contact, "activity_id")

    cond do
      raw_id in [nil, ""] -> "missing_contact_id"
      stable_id?(raw_id) -> nil
      true -> "invalid_contact_id"
    end
  end

  def contact_spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"]) ||
      stable_id_or_nil(contact["scenario_id"])
  end

  def contact_identity_issue(contact, stable_identity_fields) do
    Enum.find_value(stable_identity_fields, fn field ->
      value = Map.get(contact, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  def stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  def stable_id?("nil"), do: false
  def stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  def stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  def stable_id?(_value), do: false

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def normalize_station_calendar_id_lists(context) do
    Enum.reduce(
      [
        "station_calendar_overlap_entry_ids",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_reservation_ids"
      ],
      context,
      fn field, acc ->
        case normalize_id_list(Map.get(acc, field)) do
          nil -> Map.delete(acc, field)
          ids -> Map.put(acc, field, ids)
        end
      end
    )
  end

  def normalize_station_calendar_number_lists(context, numeric) do
    Enum.reduce(
      ["station_calendar_reservation_expires_at_s"],
      context,
      fn field, acc ->
        case normalize_number_list(Map.get(acc, field), numeric) do
          nil -> Map.delete(acc, field)
          values -> Map.put(acc, field, values)
        end
      end
    )
  end

  def contact_station_calendar_entry_id(contact) do
    stable_id_or_nil(contact["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(contact, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "id"]))
  end

  def contact_station_calendar_provider_id(contact) do
    stable_id_or_nil(contact["station_calendar_provider_id"]) ||
      stable_id_or_nil(
        get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_id"])
      ) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "provider_id"])) ||
      stable_id_or_nil(get_in(contact, ["provenance", "provider_id"]))
  end

  def contact_station_calendar_provider_entry_id(contact) do
    stable_id_or_nil(contact["station_calendar_provider_entry_id"]) ||
      stable_id_or_nil(
        get_in(contact, ["source_station_calendar_entry", "station_calendar_provider_entry_id"])
      ) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(get_in(contact, ["source_station_calendar_entry", "id"]))
  end

  def reservation_expires_at_s(contact, numeric) do
    [
      contact["station_reservation_expires_at_s"],
      contact["reservation_expires_at_s"],
      contact["reservation_hold_expires_at_s"],
      contact["hold_expires_at_s"],
      contact["expires_at_s"],
      contact["expires_at"],
      get_in(contact, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(contact, ["source_station_calendar_entry", "expires_at_s"])
    ]
    |> Enum.find_value(numeric)
  end

  def derive_station_calendar_counts(context) do
    context
    |> derive_station_calendar_count(
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids"
    )
    |> derive_station_calendar_count(
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids"
    )
    |> derive_station_calendar_count(
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_ids"
    )
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp normalize_id_list(nil), do: nil

  defp normalize_id_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&id_values/1)
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp normalize_id_list(value), do: normalize_id_list([value])

  defp normalize_number_list(nil, _numeric), do: nil

  defp normalize_number_list(values, numeric) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(numeric)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value, numeric), do: normalize_number_list([value], numeric)

  defp derive_station_calendar_count(context, count_field, id_field) do
    case Map.get(context, id_field) do
      ids when is_list(ids) -> Map.put(context, count_field, length(ids))
      _ids -> context
    end
  end

  defp id_values(%{} = value) do
    ["id", "station_calendar_entry_id", "station_reservation_id", "reservation_id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value), do: [value]

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_value()

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value),
    do: if(stable_id?(value), do: [value], else: [])

  defp stable_id_value(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_value()

  defp stable_id_value(_value), do: []
end
