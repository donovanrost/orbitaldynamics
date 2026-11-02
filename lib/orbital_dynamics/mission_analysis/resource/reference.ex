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

           unless m["model"] == "battery",
             do: raise(ArgumentError, "unsupported reference resource model")

           %{
             id: m["id"],
             module: Battery,
             configuration: m["configuration"],
             exclusive_cost_keys: ["energy_wh"]
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
