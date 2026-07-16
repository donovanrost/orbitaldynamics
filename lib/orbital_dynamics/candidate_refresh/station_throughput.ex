defmodule OrbitalDynamics.CandidateRefresh.StationThroughput do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def factor(
        _refresh,
        _ground_station_id,
        %{
          "provenance" => %{"station_throughput_factor_source" => "operational_feedback"}
        },
        _operational_feedback
      ),
      do: {1.0, nil}

  def factor(refresh, ground_station_id, _station_state, operational_feedback) do
    factors =
      refresh
      |> operational_feedback.()
      |> Map.get("station_throughput_factor")

    case factors do
      %{} ->
        station_id = encode_value(ground_station_id)

        cond do
          is_number(Map.get(factors, station_id)) ->
            {clamped_factor(Map.get(factors, station_id)),
             "operational_feedback.station_throughput_factor.station"}

          is_number(Map.get(factors, "default")) ->
            {clamped_factor(Map.get(factors, "default")),
             "operational_feedback.station_throughput_factor.default"}

          true ->
            {1.0, nil}
        end

      _other ->
        {1.0, nil}
    end
  end

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)

  defp clamped_factor(value), do: value |> max(0.0) |> min(1.0)
end
