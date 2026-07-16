defmodule OrbitalDynamics.CandidateRefresh.ContactSuccess do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def factor(refresh, ground_station_id, operational_feedback) do
    rates =
      refresh
      |> operational_feedback.()
      |> Map.get("contact_success_rate")

    case rates do
      %{} ->
        station_id = encode_value(ground_station_id)

        cond do
          is_number(Map.get(rates, station_id)) ->
            {clamped_factor(Map.get(rates, station_id)),
             "operational_feedback.contact_success_rate.station"}

          is_number(Map.get(rates, "default")) ->
            {clamped_factor(Map.get(rates, "default")),
             "operational_feedback.contact_success_rate.default"}

          true ->
            {1.0, "not_declared"}
        end

      _other ->
        {1.0, "not_declared"}
    end
  end

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)

  defp clamped_factor(value), do: value |> max(0.0) |> min(1.0)
end
