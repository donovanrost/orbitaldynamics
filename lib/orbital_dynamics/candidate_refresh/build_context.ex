defmodule OrbitalDynamics.CandidateRefresh.BuildContext do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.FreshnessReport

  def accepted_planning_state_ref(refresh) do
    accepted_state = accepted_planning_state(refresh)

    accepted_state
    |> accepted_planning_state_identity()
    |> Map.merge(%{
      "spacecraft_state_count" => length(Map.get(accepted_state, "spacecraft_states", [])),
      "maneuver_execution_delta_count" =>
        length(Map.get(accepted_state, "maneuver_execution_deltas", []))
    })
  end

  def accepted_planning_state_provenance(refresh) do
    accepted_state = accepted_planning_state(refresh)

    accepted_state
    |> accepted_planning_state_identity()
    |> Map.merge(%{
      "source" => Map.get(accepted_state, "source", %{}),
      "quality" => Map.get(accepted_state, "quality", %{}),
      "provenance" => Map.get(accepted_state, "provenance", %{})
    })
  end

  def accepted_planning_state(refresh) do
    Map.get(refresh, "accepted_planning_state") || %{}
  end

  def freshness_report(refresh, generated_at, model_limits, numeric_value) do
    FreshnessReport.build(%{
      accepted_state: accepted_planning_state(refresh),
      current_epoch_s: current_epoch_s(refresh, numeric_value),
      generated_at: generated_at,
      horizon: remaining_horizon(refresh, numeric_value),
      model_limits: model_limits.(),
      refresh: refresh
    })
  end

  def snapshot_id(refresh), do: Map.get(accepted_planning_state(refresh), "snapshot_id")

  def current_epoch_s(refresh, numeric_value) do
    [
      Map.get(refresh, "current_epoch_s"),
      get_in(refresh, ["current_epoch", "seconds_since_j2000"]),
      get_in(refresh, ["mission_state", "current_epoch_s"]),
      get_in(refresh, ["mission_state", "current_epoch", "seconds_since_j2000"]),
      get_in(refresh, ["accepted_planning_state", "current_epoch_s"]),
      get_in(refresh, ["accepted_planning_state", "current_epoch", "seconds_since_j2000"]),
      accepted_state_spacecraft_epoch_s(refresh, numeric_value)
    ]
    |> Enum.find_value(numeric_value)
  end

  def remaining_horizon(refresh, numeric_value) do
    [
      Map.get(refresh, "remaining_horizon"),
      get_in(refresh, ["mission_state", "remaining_horizon"]),
      get_in(refresh, ["accepted_planning_state", "remaining_horizon"])
    ]
    |> Enum.find(&is_map/1)
    |> case do
      %{} = horizon -> normalize_remaining_horizon(horizon, numeric_value)
      _horizon -> %{}
    end
  end

  defp accepted_state_spacecraft_epoch_s(refresh, numeric_value) do
    refresh
    |> accepted_planning_state()
    |> Map.get("spacecraft_states", [])
    |> List.first(%{})
    |> get_in(["epoch", "seconds_since_j2000"])
    |> then(numeric_value)
  end

  defp accepted_planning_state_identity(accepted_state) do
    %{
      "snapshot_id" => Map.get(accepted_state, "snapshot_id"),
      "accepted_at" => Map.get(accepted_state, "accepted_at")
    }
  end

  defp normalize_remaining_horizon(horizon, numeric_value) do
    horizon
    |> Map.take(["starts_at_s", "ends_at_s", "duration_s", "output_step_s"])
    |> Map.new(fn {key, value} ->
      case numeric_value.(value) do
        number when is_number(number) -> {key, number}
        nil -> {key, value}
      end
    end)
  end
end
