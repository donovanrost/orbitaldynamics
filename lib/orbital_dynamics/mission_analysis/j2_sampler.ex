defmodule OrbitalDynamics.MissionAnalysis.J2Sampler do
  @moduledoc """
  Evaluates times from fixed J2 integration anchors, without advancing the anchors.

  Queries between anchors use local RK4 repropagation from the preceding anchor,
  never Cartesian linear interpolation. Changing query cadence therefore does not
  change the main integration mesh. This is an Earth reference-adapter utility;
  the generic refinement API accepts any caller-owned state sampler.
  """
  alias OrbitalDynamics.{Epoch, Scenario, Spacecraft, StateVector}
  alias OrbitalDynamics.Propagators.J2

  def new!(assets, body, anchor_step_s) do
    OrbitalDynamics.MissionAnalysis.Input.positive!(anchor_step_s, "anchor_step_s")

    tables =
      Map.new(assets, fn asset ->
        states = asset.trajectory.states

        unless is_list(states) and length(states) >= 2,
          do: raise(ArgumentError, "at least two J2 anchors required")

        first = hd(states).epoch.seconds_since_j2000
        last = List.last(states)

        unless length(states) >= 2 and
                 Enum.chunk_every(states, 2, 1, :discard)
                 |> Enum.all?(fn [a, b] ->
                   dt = b.epoch.seconds_since_j2000 - a.epoch.seconds_since_j2000
                   dt > 0 and dt <= anchor_step_s + 1.0e-6
                 end) and
                 Enum.with_index(states)
                 |> Enum.all?(fn {s, i} ->
                   s == last or
                     abs(s.epoch.seconds_since_j2000 - first - i * anchor_step_s) < 1.0e-6
                 end),
               do:
                 raise(
                   ArgumentError,
                   "J2 sampler requires ordered uniform anchors with at most a shorter final interval"
                 )

        {asset.id, {List.to_tuple(states), first, List.last(states).epoch.seconds_since_j2000}}
      end)

    fn asset, t ->
      {states, start, stop} = Map.fetch!(tables, asset.id)

      if t < start or t > stop do
        {:error, :state_sampler_outside_coverage}
      else
        index = min(trunc(:math.floor((t - start) / anchor_step_s)), tuple_size(states) - 1)
        index = locate(states, index, t)
        anchor = elem(states, index)
        delta = t - anchor.epoch.seconds_since_j2000

        cond do
          delta == 0 ->
            {:ok, anchor}

          delta < 0 ->
            {:error, :state_sampler_anchor_mismatch}

          true ->
            scenario =
              Scenario.new!("j2-local-sample", Spacecraft.new!("sampler", 1), anchor,
                duration_s: delta,
                output_step_s: delta,
                central_body: body
              )

            with {:ok, trajectory} <- J2.propagate(scenario, max_step_s: anchor_step_s) do
              %StateVector{} = state = List.last(trajectory.states)
              {:ok, %StateVector{state | epoch: Epoch.new!(t, anchor.epoch.scale)}}
            end
        end
      end
    end
  end

  defp locate(states, i, t) do
    cond do
      i > 0 and elem(states, i).epoch.seconds_since_j2000 > t ->
        locate(states, i - 1, t)

      i < tuple_size(states) - 1 and elem(states, i + 1).epoch.seconds_since_j2000 <= t ->
        locate(states, i + 1, t)

      true ->
        i
    end
  end
end
