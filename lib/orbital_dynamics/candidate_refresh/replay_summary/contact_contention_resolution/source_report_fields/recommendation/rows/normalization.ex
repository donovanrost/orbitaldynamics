defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows.Normalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def normalize_count_token(value) do
    value
    |> encode_value()
    |> case do
      nil -> nil
      value when is_binary(value) -> value |> String.trim() |> String.downcase()
      value -> value
    end
  end

  def encode_value(value), do: ValueEncoding.encode_value(value)

  def non_empty_map(nil), do: nil
  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map
end
