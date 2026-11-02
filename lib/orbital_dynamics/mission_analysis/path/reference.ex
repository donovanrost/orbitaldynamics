defmodule OrbitalDynamics.MissionAnalysis.Path.Reference do
  @moduledoc false
  alias OrbitalDynamics.MissionAnalysis.Path.{Policy, Checks.Angular, Checks.ReflectedBeam}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S

  def policy!(config) do
    S.fields!(
      config,
      ~w(assets sample_steps_s max_evaluations max_samples_per_segment),
      "path policy"
    )

    assets =
      Map.new(config["assets"], fn {id, a} ->
        S.fields!(a, ~w(activity_modes transition_mode modes rules), "asset path policy")

        rules =
          Enum.map(a["rules"], fn r ->
            S.fields!(r, ~w(id model configuration), "reference path rule")

            module =
              case r["model"] do
                "angular" -> Angular
                "reflected_beam" -> ReflectedBeam
                _ -> raise ArgumentError, "unsupported reference path rule"
              end

            %{id: r["id"], module: module, configuration: r["configuration"]}
          end)

        {id,
         %{
           activity_modes: a["activity_modes"],
           transition_mode: a["transition_mode"],
           modes: a["modes"],
           rules: rules
         }}
      end)

    Policy.new!(assets,
      sample_steps_s: config["sample_steps_s"],
      max_evaluations: config["max_evaluations"],
      max_samples_per_segment: config["max_samples_per_segment"]
    )
  end
end
