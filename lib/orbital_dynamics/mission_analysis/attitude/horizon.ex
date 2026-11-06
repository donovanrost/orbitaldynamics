defmodule OrbitalDynamics.MissionAnalysis.Attitude.Horizon do
  @moduledoc "Explicit finite planning horizon and fixed inertial terminal attitudes."
  alias OrbitalDynamics.{Epoch, Frame}
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Motion, Quaternion}
  alias OrbitalDynamics.MissionAnalysis.Path.Runner

  def new!(nil), do: nil

  def new!(%{start: %Epoch{} = start, stop: %Epoch{} = stop, terminals: terminals} = h)
      when map_size(h) == 3 and is_map(terminals) do
    Input.number!(start.seconds_since_j2000, "horizon start", -1.0e12, 1.0e12)
    Input.number!(stop.seconds_since_j2000, "horizon stop", -1.0e12, 1.0e12)

    unless start.scale in [:utc, :tai, :tdb] and start.scale == stop.scale and
             stop.seconds_since_j2000 > start.seconds_since_j2000,
           do: raise(ArgumentError, "horizon requires ordered epochs in one explicit scale")

    terminals =
      Map.new(terminals, fn {id, terminal} ->
        Input.id!(id)

        value =
          case terminal do
            :unknown ->
              :unknown

            %{
              frame: %Frame{},
              quaternion: q,
              mode: mode,
              angular_velocity_deg_s: w,
              boundary: true
            } = t
            when map_size(t) == 5 ->
              Input.id!(mode)

              %{
                t
                | quaternion: Quaternion.new!(q),
                  angular_velocity_deg_s: Input.vector!(w, "boundary angular velocity")
              }

            %{frame: %Frame{}, quaternion: q, mode: mode} = t when map_size(t) == 3 ->
              unless mode == :unknown or is_binary(mode),
                do: raise(ArgumentError, "terminal mode must be declared or :unknown")

              if is_binary(mode), do: Input.id!(mode)
              %{t | quaternion: Quaternion.new!(q)}

            _ ->
              raise ArgumentError,
                    "terminal requires an inertial frame, quaternion and payload mode, or :unknown"
          end

        {id, value}
      end)

    %{start: start, stop: stop, terminals: terminals}
  end

  def new!(_), do: raise(ArgumentError, "invalid planning horizon")

  def describe(nil), do: :null

  def describe(h) do
    %{
      "starts_at_s" => h.start.seconds_since_j2000,
      "ends_at_s" => h.stop.seconds_since_j2000,
      "time_scale" => Atom.to_string(h.start.scale),
      "terminal_strategy" =>
        if(Enum.any?(h.terminals, fn {_, t} -> is_map(t) and t[:boundary] == true end),
          do: "explicit_activity_boundary_and_fixed_inertial_terminals",
          else: "brake_slew_settle_then_fixed_inertial_hold_at_zero_rate"
        ),
      "terminals" =>
        Map.new(h.terminals, fn {id, t} ->
          {id,
           if(t == :unknown,
             do: %{"status" => "unknown"},
             else:
               %{
                 "quaternion_wxyz" => Tuple.to_list(t.quaternion),
                 "frame" => Atom.to_string(t.frame.name),
                 "frame_center" => Atom.to_string(t.frame.center),
                 "frame_orientation" => Atom.to_string(t.frame.orientation),
                 "mode" => if(t.mode == :unknown, do: :null, else: t.mode)
               }
               |> then(fn row ->
                 if t[:boundary],
                   do:
                     Map.put(
                       row,
                       "angular_velocity_inertial_deg_s",
                       Tuple.to_list(t.angular_velocity_deg_s)
                     ),
                   else: row
               end)
           )}
        end)
    }
  end

  def validate!(assets, policy) do
    if h = policy.horizon do
      Enum.each(h.terminals, fn {id, t} ->
        unless Map.has_key?(assets, id),
          do: raise(ArgumentError, "terminal names unknown asset #{id}")

        first = hd(assets[id].trajectory.states)

        unless t == :unknown or Frame.compatible?(t.frame, first.frame),
          do: raise(ArgumentError, "terminal frame must match asset inertial frame")
      end)

      Enum.each(assets, fn {_, asset} ->
        unless hd(asset.trajectory.states).epoch.scale == h.start.scale,
          do: raise(ArgumentError, "horizon time scale must match assets")
      end)
    end
  end

  # A known initial state is required exactly at the horizon boundary: there is no
  # implicit propagation of an attitude from an earlier epoch, or uncovered prefix.
  def readiness(asset, policy) do
    h = policy.horizon
    limits = policy.assets[asset.id]
    terminal = h.terminals[asset.id]

    cond do
      limits == nil ->
        :attitude_configuration_missing

      limits.initial == :unknown ->
        :initial_attitude_unknown

      limits.initial.epoch.seconds_since_j2000 != h.start.seconds_since_j2000 ->
        :initial_epoch_not_horizon_start

      terminal in [nil, :unknown] ->
        :terminal_attitude_unknown

      terminal.mode == :unknown ->
        :terminal_mode_unknown

      hd(asset.trajectory.states).epoch.seconds_since_j2000 > h.start.seconds_since_j2000 or
          List.last(asset.trajectory.states).epoch.seconds_since_j2000 <
            h.stop.seconds_since_j2000 ->
        :horizon_outside_trajectory_coverage

      policy.path_constraints == nil ->
        :horizon_path_constraints_missing

      true ->
        nil
    end
  end

  def transition(asset, source, policy) do
    h = policy.horizon
    t = h.terminals[asset.id]

    destination = %{
      "epoch_s" => h.stop.seconds_since_j2000,
      "quaternion_wxyz" => Tuple.to_list(t.quaternion),
      "angular_velocity_inertial_deg_s" =>
        if(t[:boundary], do: Tuple.to_list(t.angular_velocity_deg_s), else: [0, 0, 0])
    }

    OrbitalDynamics.MissionAnalysis.Attitude.SavedMotion.terminal(
      source,
      destination,
      policy.assets[asset.id],
      fn ->
        if t[:boundary],
          do: Motion.continuity(source, destination, policy.assets[asset.id]),
          else: Motion.transition(source, destination, policy.assets[asset.id], :terminal)
      end
    )
  end

  def check(asset, plan, policy, state_at, cache) do
    Runner.transition_in_mode(
      asset,
      plan,
      "terminal_transition_and_hold",
      policy.horizon.terminals[asset.id].mode,
      state_at,
      cache
    )
  end

  def finish(assets, activities, policy, state_at, cache),
    do:
      finish(assets, activities, policy, state_at, cache, fn report, cache ->
        {:ok, report, cache}
      end)

  @doc false
  def finish(_assets, _activities, %{horizon: nil}, _state_at, cache, done),
    do: done.(:null, cache)

  def finish(assets, activities, policy, state_at, cache, done) do
    finish_assets(Enum.sort(assets), activities, policy, state_at, cache, %{}, done)
  end

  defp finish_assets([], _activities, _policy, _state_at, cache, reports, done) do
    statuses = Enum.map(reports, fn {_, r} -> r["status"] end)

    status =
      cond do
        "violated" in statuses -> "violated"
        statuses == [] or "unknown" in statuses -> "unknown"
        true -> "supported"
      end

    report =
      %{
        "status" => status,
        "assets" => reports,
        "limits" =>
          "Full declared horizon at tested epochs only; includes all idle assets. Terminal modes and instantaneous switches are assumptions, not hardware validation."
      }

    done.(report, cache)
  end

  defp finish_assets([{id, asset} | rest], activities, policy, state_at, cache, reports, done) do
    case finish_asset(id, asset, activities, policy, state_at, cache) do
      {:ok, report, cache} ->
        finish_assets(
          rest,
          activities,
          policy,
          state_at,
          cache,
          Map.put(reports, id, report),
          done
        )

      error ->
        error
    end
  end

  defp finish_asset(id, asset, activities, policy, state_at, cache) do
    h = policy.horizon
    timeline = Enum.filter(activities, &(&1["asset_id"] == id))
    last = List.last(timeline)

    base = %{
      "starts_at_s" => h.start.seconds_since_j2000,
      "ends_at_s" => h.stop.seconds_since_j2000,
      "scheduled_activity_count" => length(timeline)
    }

    result =
      case readiness(asset, policy) do
        nil ->
          source =
            if last,
              do: List.last(last["attitude_profile"]),
              else: pose(policy.assets[id].initial)

          case transition(asset, source, policy) do
            {:infeasible, evidence} ->
              {:result, "violated", base, evidence, source["epoch_s"], cache}

            {:ok, plan} ->
              case check(asset, plan, policy, state_at, cache) do
                {status, evidence, cache} when status == :ok ->
                  {:result, "supported", Map.put(base, "terminal_motion", plan), evidence,
                   source["epoch_s"], cache}

                {status, _reason, evidence, cache} when status in [:unknown, :infeasible] ->
                  {:result, if(status == :unknown, do: "unknown", else: "violated"),
                   Map.put(base, "terminal_motion", plan), evidence, source["epoch_s"], cache}

                {:error, reason, _cache} ->
                  {:error, reason}
              end
          end

        reason ->
          {:result, "unknown", base, %{"reason" => Atom.to_string(reason)},
           h.start.seconds_since_j2000, cache}
      end

    case result do
      {:result, status, base, evidence, tail_start, cache} ->
        report =
          Map.merge(base, %{
            "status" => status,
            "terminal_path_evidence" => evidence,
            "uncovered_intervals" =>
              if(status == "supported",
                do: [],
                else: [
                  %{
                    "starts_at_s" => tail_start,
                    "ends_at_s" => h.stop.seconds_since_j2000,
                    "reason" => "not_fully_supported",
                    "status" => status
                  }
                ]
              )
          })

        # No later finalization stage queries this asset's path rules.
        cache = Runner.release_asset(cache, id)
        # This asset's terminal evidence is closed; project it before retaining the fleet.
        report =
          Map.update!(
            report,
            "terminal_path_evidence",
            &OrbitalDynamics.MissionAnalysis.ReportData.complete/1
          )

        {:ok, report, cache}

      error ->
        error
    end
  end

  defp pose(i),
    do: %{
      "epoch_s" => i.epoch.seconds_since_j2000,
      "quaternion_wxyz" => Tuple.to_list(i.quaternion),
      "angular_velocity_inertial_deg_s" => Tuple.to_list(i.angular_velocity_deg_s)
    }
end
