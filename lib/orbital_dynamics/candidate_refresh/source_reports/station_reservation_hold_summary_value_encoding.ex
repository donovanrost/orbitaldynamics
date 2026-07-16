defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryValueEncoding do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryStableIds

  def stable_id_or_nil(value), do: StationReservationHoldSummaryStableIds.stable_id_or_nil(value)

  def normalized_source_report_token(value) do
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

  def numeric_or_nil(value), do: numeric_value(value)

  def stringify_keys(value), do: StationReservationHoldSummaryEncoding.stringify_keys(value)

  def encode_value(value), do: StationReservationHoldSummaryEncoding.encode_value(value)

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
