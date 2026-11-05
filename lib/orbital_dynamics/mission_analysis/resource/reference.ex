defmodule OrbitalDynamics.MissionAnalysis.Resource.Reference do
  @moduledoc false
  alias OrbitalDynamics.MissionAnalysis.Resource.{Policy, Battery}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S

  def policy!(c) do
    S.fields!(
      c,
      ~w(assets sample_steps_s max_intervals_per_asset max_evaluations),
      "resource policy"
    )

    assets =
      Map.new(c["assets"], fn {id, models} ->
        {id,
         Enum.map(models, fn m ->
           S.fields!(m, ~w(id model configuration), "reference resource model")

           {module, keys} =
             case m["model"] do
               "battery" ->
                 {Battery, ["energy_wh"]}

               "thermal" ->
                 {OrbitalDynamics.MissionAnalysis.Resource.Thermal, ["temperature_k"]}

               "reaction_wheels" ->
                 {OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels,
                  ~w(wheel_momentum_nms wheel_1_momentum_nms wheel_2_momentum_nms wheel_3_momentum_nms)}

               _ ->
                 raise ArgumentError, "unsupported reference resource model"
             end

           %{
             id: m["id"],
             module: module,
             configuration: m["configuration"],
             exclusive_cost_keys: keys
           }
         end)}
      end)

    Policy.new!(assets,
      sample_steps_s: c["sample_steps_s"],
      max_intervals_per_asset: c["max_intervals_per_asset"],
      max_evaluations: c["max_evaluations"]
    )
  end
end
