defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report.Rows.Identity do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def station_id(row) do
    [
      row["ground_station_id"],
      row["station_id"],
      nested_station_id(row)
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  def spacecraft_id(row) do
    [
      row["spacecraft_id"],
      row["source_spacecraft_id"],
      row["scenario_id"],
      row
      |> source_contact_values()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)
      |> Enum.flat_map(fn contact ->
        [
          contact["spacecraft_id"],
          contact["scenario_id"],
          get_in(contact, ["spacecraft", "id"]),
          get_in(contact, ["satellite", "id"])
        ]
      end)
    ]
    |> List.flatten()
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_contact_values(row) do
    [
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["actual_throughput_contact_ids"],
      row["actual_throughput_contact_id"],
      row["actual_completion_contact_ids"],
      row["actual_completion_contact_id"],
      row["required_downlink_contact_ids"],
      row["required_downlink_contact_id"],
      row["contact_ids"],
      row["contact_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["actual_throughput_contacts"],
      row["actual_throughput_contact"],
      row["actual_completion_contacts"],
      row["actual_completion_contact"],
      row["required_downlink_contacts"],
      row["required_downlink_contact"],
      row["source_contacts"],
      row["source_contact"],
      row["contacts"],
      row["contact"]
    ]
    |> List.flatten()
  end

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
