defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineEmbeddedRowSource do
  @moduledoc false

  def source_row(%{} = row) do
    case source_value(row) do
      %{} = timeline_row -> stringify_keys(timeline_row)
      _timeline_row -> %{}
    end
  end

  defp source_value(row) do
    cond do
      is_map(row["source_operational_timeline"]) ->
        row["source_operational_timeline"]

      is_map(get_in(row, ["source_review_row", "source_operational_timeline"])) ->
        get_in(row, ["source_review_row", "source_operational_timeline"])

      true ->
        %{}
    end
  end

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
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
