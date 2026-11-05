defmodule OrbitalDynamics.MissionAnalysis.Attitude.Profile do
  @moduledoc false
  alias OrbitalDynamics.{Frame, Vector3}
  alias OrbitalDynamics.MissionAnalysis.Evaluation
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion}

  def sample(asset, request, session, t, configuration, policy, state_at, cache) do
    h = policy.derivative_step_s

    times = [t - 2 * h, t - h, t, t + h, t + 2 * h]

    if Enum.chunk_every(times, 2, 1, :discard) |> Enum.all?(fn [a, b] -> b > a end) do
      with {:ok, values, cache} <-
             orientations(
               asset,
               request,
               session,
               times,
               configuration,
               policy,
               state_at,
               cache
             ) do
        [qm2, qm, q, qp, qp2] = values
        [tm2, tm, _, tp, tp2] = times
        omega = Vector3.scale(Quaternion.delta(qm, qp), 1 / (tp - tm))
        omega_before = Vector3.scale(Quaternion.delta(qm2, q), 1 / (t - tm2))
        omega_after = Vector3.scale(Quaternion.delta(q, qp2), 1 / (tp2 - t))
        accel = Vector3.scale(Vector3.subtract(omega_after, omega_before), 2 / (tp2 - tm2))

        point = %{
          "epoch_s" => t,
          "quaternion_wxyz" => Tuple.to_list(q),
          "angular_velocity_inertial_deg_s" => Tuple.to_list(omega),
          "angular_acceleration_inertial_deg_s2" => Tuple.to_list(accel),
          "rate_deg_s" => Vector3.norm(omega),
          "accel_deg_s2" => Vector3.norm(accel)
        }

        point =
          if policy.assets[asset.id][:rigid_body],
            do:
              Map.put(
                point,
                "rigid_body_torque",
                OrbitalDynamics.MissionAnalysis.Attitude.RigidBody.at(
                  point,
                  policy.assets[asset.id].rigid_body
                )
              ),
            else: point

        {:ok, point, cache}
      end
    else
      {:unknown, :attitude_derivative_epoch_precision_exhausted, cache}
    end
  end

  def tracking(
        asset,
        request,
        session,
        start,
        stop,
        configuration,
        policy,
        refinement,
        state_at,
        cache
      ) do
    count = trunc(:math.floor((stop - start) / policy.profile_step_s))

    if count > 10_000 do
      {:unknown, :profile_sample_limit, cache}
    else
      times =
        (Enum.map(0..count, &(start + &1 * policy.profile_step_s)) ++ [stop])
        |> Enum.uniq_by(&(&1 * 1.0))
        |> Enum.sort()

      Enum.reduce_while(times, {:ok, [], cache}, fn t, {:ok, points, cache} ->
        result =
          with {:ok, point, cache} <-
                 sample(asset, request, session, t, configuration, policy, state_at, cache),
               {:ok, evaluation, cache} <-
                 physical(asset, request, session, t, policy, refinement, state_at, cache) do
            limits = policy.assets[asset.id]

            cond do
              not Evaluation.feasible?(evaluation) ->
                {:infeasible, {:activity_sample_ineligible, t}, cache}

              point["rate_deg_s"] > limits.max_rate_deg_s ->
                {:infeasible, {:tracking_rate_exceeds_limit, t, point["rate_deg_s"]}, cache}

              point["accel_deg_s2"] > limits.max_accel_deg_s2 ->
                {:infeasible, {:tracking_acceleration_exceeds_limit, t, point["accel_deg_s2"]},
                 cache}

              get_in(point, ["rigid_body_torque", "status"]) == "violated" ->
                {:infeasible, {:tracking_torque_exceeds_limit, t, point["rigid_body_torque"]},
                 cache}

              true ->
                {:ok, point, cache}
            end
          end

        case result do
          {:ok, p, cache} -> {:cont, {:ok, [p | points], cache}}
          other -> {:halt, other}
        end
      end)
      |> case do
        {:ok, points, cache} -> {:ok, Enum.reverse(points), cache}
        other -> other
      end
    end
  end

  defp orientations(asset, request, session, times, configuration, policy, state_at, cache) do
    Enum.reduce_while(times, {:ok, [], cache}, fn t, {:ok, values, cache} ->
      case orientation(asset, request, session, t, configuration, policy, state_at, cache) do
        {:ok, q, cache} -> {:cont, {:ok, [q | values], cache}}
        other -> {:halt, other}
      end
    end)
    |> case do
      {:ok, values, cache} -> {:ok, Enum.reverse(values), cache}
      other -> other
    end
  end

  def orientation(asset, request, session, t, configuration, policy, state_at, cache) do
    first = hd(asset.trajectory.states).epoch.seconds_since_j2000
    last = List.last(asset.trajectory.states).epoch.seconds_since_j2000

    cond do
      t < first or t > last ->
        {:unknown, :profile_derivative_outside_coverage, cache}

      not function_exported?(request.model, :pointing, 3) ->
        {:unknown, :pointing_model_unavailable, cache}

      true ->
        cached({:orientation, asset.id, request.id, t * 1.0}, policy, cache, fn ->
          with {:ok, state} <- state_at.(asset, t) do
            case request.model.pointing(state, session, configuration) do
              {:ok, %Pointing{} = p} ->
                p = Pointing.new!(p.frame, p.quaternion)

                unless Frame.compatible?(p.frame, state.frame),
                  do: raise(ArgumentError, "pointing frame must match sampled inertial frame")

                {:ok, p.quaternion}

              {:unknown, reason} ->
                {:unknown, reason}

              {:error, reason} ->
                {:error, reason}

              _ ->
                {:error, :invalid_pointing_result}
            end
          end
        end)
    end
  end

  defp physical(asset, request, session, t, policy, refinement, state_at, cache) do
    cached({:physical, asset.id, request.id, t * 1.0}, policy, cache, fn ->
      before = t - refinement.tracking_lookback_s
      start = hd(asset.trajectory.states).epoch.seconds_since_j2000

      with {:ok, state} <- state_at.(asset, t),
           {:ok, prior} <- if(before >= start, do: state_at.(asset, before), else: {:ok, nil}) do
        case request.model.evaluate(state, prior, session) do
          {:ok, %Evaluation{} = e} -> {:ok, Evaluation.new!(e.checks, e.metrics)}
          {:error, reason} -> {:error, reason}
          _ -> {:error, :invalid_model_evaluation}
        end
      end
    end)
  end

  defp cached(key, policy, cache, evaluate) do
    case Map.fetch(cache.values, key) do
      {:ok, {status, value}} ->
        {status, value, cache}

      :error ->
        if cache.evaluations >= policy.max_evaluations do
          {:error, :attitude_evaluation_budget_exhausted, cache}
        else
          OrbitalDynamics.MissionAnalysis.Scheduling.Work.charge!("attitude")
          {status, value} = evaluate.()

          cache = %{
            cache
            | values: Map.put(cache.values, key, {status, value}),
              evaluations: cache.evaluations + 1
          }

          {status, value, cache}
        end
    end
  end
end
