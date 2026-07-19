defmodule OrbitalDynamics.Communications.LinkCapacity.ContactIdentity do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @stable_fields ~w(scenario_id spacecraft_id satellite_id ground_station_id)

  def stable_fields, do: @stable_fields

  def contact_id!(contact) do
    case contact_id_or_nil(contact) do
      value when is_binary(value) and value != "" -> value
      _value -> raise ArgumentError, "contact id is required"
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

  def ground_station_id(contact), do: stable_id_or_nil(contact["ground_station_id"])

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

  def contact_identity_issue(contact) do
    Enum.find_value(@stable_fields, fn field ->
      value = Map.get(contact, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  def spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"])
  end

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false
end
