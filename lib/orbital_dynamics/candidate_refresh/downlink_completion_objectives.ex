defmodule OrbitalDynamics.CandidateRefresh.DownlinkCompletionObjectives do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ObjectiveMatching
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(refresh, refresh_objectives) do
    refresh
    |> refresh_objectives.()
    |> Enum.filter(fn
      %{"type" => type} when type in ["downlink_completion", "required_downlink_completion"] ->
        true

      _objective ->
        false
    end)
  end

  def context(refresh, scenario_id, ground_station_id, refresh_objectives) do
    objectives =
      refresh
      |> objectives(refresh_objectives)
      |> Enum.filter(
        &ObjectiveMatching.matches_downlink_candidate?(
          &1,
          refresh,
          scenario_id,
          ground_station_id
        )
      )

    %{
      "downlink_completion_objective_count" => length(objectives),
      "source_capacity_adjusted_throughput_mb" =>
        sum_objective_numeric_values(objectives, "source_capacity_adjusted_throughput_mb"),
      "source_selected_capacity_adjusted_throughput_mb" =>
        sum_objective_numeric_values(
          objectives,
          "source_selected_capacity_adjusted_throughput_mb"
        ),
      "source_unused_capacity_adjusted_throughput_mb" =>
        sum_objective_numeric_values(objectives, "source_unused_capacity_adjusted_throughput_mb")
    }
    |> Enum.reject(fn
      {_key, 0} -> true
      {_key, nil} -> true
      _entry -> false
    end)
    |> Map.new()
  end

  defp sum_objective_numeric_values(objectives, field) do
    values =
      objectives
      |> Enum.map(&(Map.get(&1, field) |> ValueEncoding.numeric_value()))
      |> Enum.filter(&is_number/1)

    case values do
      [] -> nil
      values -> Enum.sum(values)
    end
  end
end
