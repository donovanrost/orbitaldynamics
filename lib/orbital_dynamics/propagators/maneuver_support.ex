defmodule OrbitalDynamics.Propagators.ManeuverSupport do
  @moduledoc false

  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.{Frame, Scenario, StateVector, Vector3}

  @time_epsilon_s 1.0e-9

  def validate_scalar_maneuvers(%Scenario{} = scenario, _max_step_s) do
    scenario.maneuvers
    |> Enum.reduce_while(:ok, fn maneuver, :ok ->
      case validate_maneuver(scenario, maneuver) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def reject_maneuver_batch(scenarios) do
    if Enum.any?(scenarios, &(Map.get(&1, :maneuvers, []) != [])) do
      {:error, {:unsupported_scenario, :maneuvers}}
    else
      :ok
    end
  end

  def elapsed_burns(%Scenario{} = scenario) do
    scenario.maneuvers
    |> Enum.map(fn maneuver ->
      {maneuver.epoch.seconds_since_j2000 - scenario.initial_state.epoch.seconds_since_j2000,
       maneuver}
    end)
    |> Enum.sort_by(fn {elapsed_s, _maneuver} -> elapsed_s end)
  end

  def apply_due_burns(%StateVector{} = state, elapsed_s, elapsed_burns) do
    {due_burns, remaining_burns} =
      Enum.split_while(elapsed_burns, fn {burn_elapsed_s, _burn} ->
        close?(burn_elapsed_s, elapsed_s)
      end)

    next_state =
      Enum.reduce(due_burns, state, fn {_elapsed_s, burn}, current_state ->
        %{
          current_state
          | velocity_km_s: Vector3.add(current_state.velocity_km_s, burn.delta_v_km_s)
        }
      end)

    {next_state, remaining_burns}
  end

  def maneuver_assumptions(maneuvers) do
    %{
      maneuver_model: :impulsive_burns,
      maneuver_count: length(maneuvers),
      total_delta_v_km_s:
        maneuvers
        |> Enum.map(&Vector3.norm(&1.delta_v_km_s))
        |> Enum.sum(),
      maneuvers: Enum.map(maneuvers, &ImpulsiveBurn.assumptions/1)
    }
  end

  defp validate_maneuver(%Scenario{} = scenario, %ImpulsiveBurn{} = maneuver) do
    elapsed_s =
      maneuver.epoch.seconds_since_j2000 - scenario.initial_state.epoch.seconds_since_j2000

    cond do
      maneuver.epoch.scale != scenario.initial_state.epoch.scale ->
        {:error, {:unsupported_maneuver, :epoch_scale}}

      not Frame.compatible?(maneuver.frame, scenario.initial_state.frame) ->
        {:error, {:unsupported_maneuver, :frame}}

      elapsed_s < -@time_epsilon_s or elapsed_s - scenario.duration_s > @time_epsilon_s ->
        {:error, {:unsupported_maneuver, :epoch_outside_scenario}}

      true ->
        :ok
    end
  end

  defp validate_maneuver(_scenario, _maneuver),
    do: {:error, {:invalid_scenario, :maneuvers}}

  defp close?(left, right), do: abs(left - right) <= @time_epsilon_s
end
