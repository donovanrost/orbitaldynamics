defmodule OrbitalDynamics.Communications.ContactContention.ContactIdentity do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.ContactNormalization

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    satellite_id
    ground_station_id
    source_window_id
  )

  def stable_identity_fields, do: @stable_identity_fields

  def spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"]) ||
      stable_id_or_nil(contact["scenario_id"])
  end

  def group_ground_station_ids(contacts) do
    contacts
    |> Enum.map(&stable_id_or_nil(&1["ground_station_id"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def group_spacecraft_ids(contacts) do
    contacts
    |> Enum.map(&spacecraft_id/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def group_stable_ids(contacts, field) do
    contacts
    |> Enum.map(&stable_id_or_nil(&1[field]))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def group_ground_station_id([ground_station_id]), do: ground_station_id
  def group_ground_station_id(_ground_station_ids), do: "multi_station"

  def group_direction(contacts) do
    case group_directions(contacts) do
      [direction] -> direction
      [] -> "downlink"
      _directions -> "mixed"
    end
  end

  def group_directions(contacts) do
    contacts
    |> Enum.map(&direction/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def direction(%{"direction" => direction}) when is_binary(direction) and direction != "",
    do: direction

  def direction(%{"type" => "command"}), do: "command"
  def direction(%{"type" => "tracking"}), do: "tracking"
  def direction(%{"type" => "health_check"}), do: "health_check"
  def direction(_contact), do: "downlink"

  def contact_id(nil), do: nil

  def contact_id(contact) do
    case contact_id_or_nil(contact) do
      value when is_binary(value) and value != "" -> value
      _value -> raise ArgumentError, "contact id is required"
    end
  end

  def contact_id_or_nil(nil), do: nil

  def contact_id_or_nil(contact) do
    case Map.get(contact, "id") || Map.get(contact, "contact_id") ||
           Map.get(contact, "activity_id") do
      value when is_binary(value) and value != "" -> stable_id_or_nil(value)
      value when is_atom(value) and not is_nil(value) -> stable_id_or_nil(value)
      value when is_integer(value) -> stable_id_or_nil(value)
      _value -> nil
    end
  end

  def id_issue(contact) do
    raw_id =
      Map.get(contact, "id") || Map.get(contact, "contact_id") ||
        Map.get(contact, "activity_id")

    cond do
      raw_id in [nil, ""] -> "missing_contact_id"
      stable_id?(raw_id) -> nil
      true -> "invalid_contact_id"
    end
  end

  def identity_issue(contact) do
    Enum.find_value(@stable_identity_fields, fn field ->
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

  def sort_key(contact) do
    {
      numeric_or_zero(contact["starts_at_s"]),
      numeric_or_zero(contact["ends_at_s"]),
      contact_id_or_nil(contact) || "",
      stable_id_or_nil(contact["scenario_id"]) || "",
      spacecraft_id(contact) || "",
      stable_id_or_nil(contact["ground_station_id"]) || "",
      stable_id_or_nil(contact["source_window_id"]) || "",
      stable_id_or_nil(contact["station_calendar_provider_id"]) || "",
      stable_id_or_nil(contact["station_calendar_provider_entry_id"]) || "",
      direction(contact)
    }
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp numeric_or_zero(value), do: ContactNormalization.numeric_or_nil(value) || 0.0
end
