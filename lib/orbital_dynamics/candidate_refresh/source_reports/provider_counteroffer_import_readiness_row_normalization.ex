defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowNormalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessStableIds

  defdelegate stringify_keys(value), to: ProviderCounterofferImportReadinessRowEncoding

  defdelegate stable_id_or_nil(value), to: ProviderCounterofferImportReadinessStableIds

  def numeric_value(value), do: ValueEncoding.numeric_value(value)

  def normalized_token(value) do
    value
    |> ProviderCounterofferImportReadinessRowEncoding.encode_value()
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

  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map
end
