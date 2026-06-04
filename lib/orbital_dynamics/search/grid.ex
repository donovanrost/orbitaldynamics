defmodule OrbitalDynamics.Search.Grid do
  @moduledoc """
  Deterministic grid expansion for simple maneuver trade studies.
  """

  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.{Epoch, Scenario, Vector3}

  @doc """
  Declares the generator model, ordering policy, and known limits.
  """
  def capabilities do
    %{
      generator: :impulsive_burn_grid,
      model: :deterministic_cartesian_delta_v_grid,
      validation_level: :assumption_declared,
      output: :scenario_candidates,
      ordering: :input_order_cartesian_product,
      random?: false,
      known_limits: [
        :impulsive_burn_only,
        :no_optimizer,
        :no_constraint_pruning,
        :no_frame_transformation
      ]
    }
  end

  @doc """
  Expands one base scenario across burn epochs and delta-v vectors.
  """
  def impulsive_burn_grid(%Scenario{} = base_scenario, opts) when is_list(opts) do
    burn_epoch_s_values = Keyword.fetch!(opts, :burn_epoch_s)
    delta_v_km_s_values = Keyword.fetch!(opts, :delta_v_km_s)
    id_prefix = Keyword.get(opts, :id_prefix, "#{base_scenario.id}_grid")

    validate!(burn_epoch_s_values, delta_v_km_s_values, id_prefix)

    for {burn_epoch_s, epoch_index} <- Enum.with_index(burn_epoch_s_values, 1),
        {delta_v_km_s, delta_v_index} <- Enum.with_index(delta_v_km_s_values, 1) do
      scenario_id = "#{id_prefix}_#{epoch_index}_#{delta_v_index}"
      burn_epoch = Epoch.shift(base_scenario.initial_state.epoch, burn_epoch_s)

      burn =
        ImpulsiveBurn.new!(
          "#{scenario_id}_burn",
          burn_epoch,
          delta_v_km_s,
          base_scenario.initial_state.frame
        )

      %Scenario{
        base_scenario
        | id: scenario_id,
          maneuvers: base_scenario.maneuvers ++ [burn]
      }
    end
  end

  defp validate!(burn_epoch_s_values, delta_v_km_s_values, id_prefix) do
    cond do
      not non_empty_numbers?(burn_epoch_s_values) ->
        raise ArgumentError, "burn_epoch_s must be a non-empty list of numeric seconds"

      not non_empty_vectors?(delta_v_km_s_values) ->
        raise ArgumentError, "delta_v_km_s must be a non-empty list of numeric {x, y, z} vectors"

      not is_binary(id_prefix) or id_prefix == "" ->
        raise ArgumentError, "id_prefix must be a non-empty string"

      true ->
        :ok
    end
  end

  defp non_empty_numbers?(values) when is_list(values) and values != [] do
    Enum.all?(values, &(is_integer(&1) or is_float(&1)))
  end

  defp non_empty_numbers?(_values), do: false

  defp non_empty_vectors?(values) when is_list(values) and values != [] do
    Enum.all?(values, &Vector3.valid?/1)
  end

  defp non_empty_vectors?(_values), do: false
end
