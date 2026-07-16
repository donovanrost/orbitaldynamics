defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization do
  @moduledoc false

  alias __MODULE__.StableIds
  alias __MODULE__.ValueEncoding

  def sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
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

  def stable_id_or_nil(value), do: StableIds.stable_id_or_nil(value)

  def stringify_keys(value), do: ValueEncoding.stringify_keys(value)

  def encode_value(value), do: ValueEncoding.encode_value(value)
end
