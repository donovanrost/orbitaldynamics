defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRowSource do
  @moduledoc false

  def embedded_source(%{} = row) do
    cond do
      is_map(row["source_link_capacity"]) ->
        row["source_link_capacity"]

      is_map(get_in(row, ["source_review_row", "source_link_capacity"])) ->
        get_in(row, ["source_review_row", "source_link_capacity"])

      true ->
        %{}
    end
    |> stringify_embedded_source()
  end

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  def encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  def encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  def encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  def encode_value(nil), do: nil
  def encode_value(value) when is_boolean(value), do: value
  def encode_value(value) when is_atom(value), do: Atom.to_string(value)
  def encode_value(value), do: value

  defp stringify_embedded_source(%{} = link_capacity_row), do: stringify_keys(link_capacity_row)
  defp stringify_embedded_source(_link_capacity_row), do: %{}
end
