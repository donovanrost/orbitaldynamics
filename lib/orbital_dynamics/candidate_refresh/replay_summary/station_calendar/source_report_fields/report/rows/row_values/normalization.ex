defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.RowValues.Normalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding
  alias __MODULE__.Directions

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def normalize_number_list(nil), do: nil

  def normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  def normalize_number_list(value), do: normalize_number_list([value])

  def summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  def stringify_keys(value), do: ValueEncoding.stringify_keys(value)

  def numeric_value(value), do: ValueEncoding.numeric_value(value)

  def normalize_direction(direction) do
    Directions.normalize_direction(direction)
  end

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def encode_value(value), do: ValueEncoding.encode_value(value)

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
