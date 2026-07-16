defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows.RowValues.Normalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "uplink",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "downlink" => "downlink",
    "down_link" => "downlink",
    "tracking" => "tracking",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "health_check" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check",
    "contact" => "contact"
  }

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def normalize_number_list(nil), do: nil

  def normalize_number_list(values) when is_list(values) do
    values
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  def normalize_number_list(value), do: normalize_number_list([value])

  def numeric_value(value), do: ValueEncoding.numeric_value(value)

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def normalize_direction(direction) when direction in [nil, ""], do: nil

  def normalize_direction(direction) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      token when is_map_key(@provider_direction_aliases, token) ->
        Map.fetch!(@provider_direction_aliases, token)

      "nil" ->
        nil

      "" ->
        nil

      value ->
        value
    end
  end

  def normalized_token(value) do
    value
    |> encode_value()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end

  def stringify_keys(value), do: ValueEncoding.stringify_keys(value)

  def encode_value(value), do: ValueEncoding.encode_value(value)

  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map

  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false
end
