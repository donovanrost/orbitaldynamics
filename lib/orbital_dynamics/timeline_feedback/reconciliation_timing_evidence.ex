defmodule OrbitalDynamics.TimelineFeedback.ReconciliationTimingEvidence do
  @moduledoc false

  def context(planned, realized, timing_variance_threshold_s) do
    start_delta_s = delta(value(realized, "actual_starts_at_s"), value(planned, "starts_at_s"))
    end_delta_s = delta(value(realized, "actual_ends_at_s"), value(planned, "ends_at_s"))
    max_timing_delta_s = max_abs_timing_delta_s(start_delta_s, end_delta_s)

    %{
      "planned_starts_at_s" => value(planned, "starts_at_s"),
      "planned_ends_at_s" => value(planned, "ends_at_s"),
      "actual_starts_at_s" => value(realized, "actual_starts_at_s"),
      "actual_ends_at_s" => value(realized, "actual_ends_at_s"),
      "start_delta_s" => start_delta_s,
      "end_delta_s" => end_delta_s,
      "max_timing_delta_s" => if(is_number(timing_variance_threshold_s), do: max_timing_delta_s),
      "timing_variance_threshold_s" => timing_variance_threshold_s,
      "timing_variance_status" =>
        timing_variance_status(max_timing_delta_s, timing_variance_threshold_s)
    }
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)

  defp delta(actual, planned) when is_number(actual) and is_number(planned), do: actual - planned
  defp delta(_actual, _planned), do: nil

  defp max_abs_timing_delta_s(start_delta_s, end_delta_s) do
    [start_delta_s, end_delta_s]
    |> Enum.filter(&is_number/1)
    |> Enum.map(&abs/1)
    |> Enum.max(fn -> nil end)
  end

  defp timing_variance_status(max_timing_delta_s, threshold)
       when is_number(max_timing_delta_s) and is_number(threshold) do
    if max_timing_delta_s > threshold, do: "exceeds_threshold", else: "within_threshold"
  end

  defp timing_variance_status(_max_timing_delta_s, _threshold), do: nil
end
