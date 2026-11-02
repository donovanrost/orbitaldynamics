defmodule OrbitalDynamics.MissionAnalysis.ReferenceResolution do
  @moduledoc "Earth/J2 reference adapter for independent sampling and integration resolution studies."
  alias OrbitalDynamics.{Epoch, CentralBody}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{J2Sampler, ReferenceMission, WindowRefinement}

  def evaluate(config, level, refinement_options) do
    with {:ok, p} <- prepare(config, level, refinement_options) do
      MissionAnalysis.run(p.assets, p.requests, p.context, p.options)
    end
  end

  @doc "Builds sampled inputs and the matching refinement policy for optional planning extensions."
  def prepare(config, level, refinement_options) do
    try do
      h = OrbitalDynamics.MissionAnalysis.Input.positive!(level["max_step_s"], "max_step_s")

      step =
        OrbitalDynamics.MissionAnalysis.Input.positive!(level["sample_step_s"], "sample_step_s")

      p = ReferenceMission.prepare!(%{config | "sample_step_s" => h, "max_step_s" => h})
      state_at = J2Sampler.new!(p.assets, CentralBody.earth(), h)

      assets =
        Enum.map(p.assets, fn asset ->
          first = hd(asset.trajectory.states)
          start = first.epoch.seconds_since_j2000 * 1.0
          stop = List.last(asset.trajectory.states).epoch.seconds_since_j2000 * 1.0
          count = trunc(:math.floor((stop - start) / step))
          if count > 9998, do: raise(ArgumentError, "too many resolution samples")

          times =
            (Enum.map(0..count, &(start + &1 * step)) ++ [stop]) |> Enum.uniq() |> Enum.sort()

          states =
            Enum.map(times, fn t ->
              {:ok, state} = state_at.(asset, t)
              %{state | epoch: Epoch.new!(t, first.epoch.scale)}
            end)

          assumptions =
            Map.merge(asset.trajectory.assumptions, %{
              "state_sampling_model" => "local_RK4_from_fixed_J2_anchors",
              "integration_anchor_step_s" => h,
              "requested_sample_step_s" => step
            })

          %{asset | trajectory: %{asset.trajectory | states: states, assumptions: assumptions}}
        end)

      policy = WindowRefinement.new!(Keyword.put(refinement_options, :state_at, state_at))

      {:ok,
       %{
         assets: assets,
         requests: p.requests,
         context: p.context,
         options: [
           max_sample_gap_s: step,
           asset_separation_s: config["asset_separation_s"],
           window_refinement: policy
         ]
       }}
    rescue
      e in [ArgumentError, KeyError, MatchError] -> {:error, Exception.message(e)}
    end
  end
end
