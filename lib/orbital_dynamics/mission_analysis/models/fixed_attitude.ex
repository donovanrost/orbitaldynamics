defmodule OrbitalDynamics.MissionAnalysis.Models.FixedAttitude do
  @moduledoc "Declared fixed body attitude task, including explicitly mode-gated momentum unloading. No payload performance physics is inferred."
  @behaviour OrbitalDynamics.MissionAnalysis.Model
  alias OrbitalDynamics.MissionAnalysis.{Evaluation, Input}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Quaternion, Pointing}
  alias OrbitalDynamics.MissionAnalysis.Path.Result
  def capabilities, do: %{"id" => "fixed_attitude"}

  def prepare(r, c, _) do
    S.fields!(c, ~w(activity_types), "fixed attitude capability")
    S.fields!(r.parameters, ~w(quaternion_wxyz), "fixed attitude parameters")

    unless is_list(c["activity_types"]) and length(c["activity_types"]) in 1..16,
      do: raise(ArgumentError, "fixed attitude activity types required")

    Enum.each(c["activity_types"], &Input.id!/1)

    {:ok,
     %{
       allowed: r.activity_type in c["activity_types"],
       kind: r.activity_type,
       q: Quaternion.new!(r.parameters["quaternion_wxyz"])
     },
     %{
       "model" => "declared_fixed_body_attitude",
       "limits" =>
         "no inferred payload performance; duration, modes, resources and path rules remain explicit"
     }}
  end

  def evaluate(_, _, s),
    do:
      {:ok,
       Evaluation.new!(
         [
           %{
             "id" => "activity_type_available",
             "passed" => s.allowed,
             "margin" => if(s.allowed, do: 1, else: -1),
             "margin_unit" => "1",
             "margin_comparison" => "min"
           }
         ],
         %{}
       )}

  def pointing(state, s, _), do: {:ok, Pointing.new!(state.frame, s.q)}

  def activity_mode(mode, s),
    do:
      {:ok,
       Result.new!(
         [
           %{
             "id" => "unload_mode",
             "status" =>
               if(
                 s.kind != "momentum_unload" or
                   get_in(mode, ["parameters", "momentum_unloading"]) == true,
                 do: "supported",
                 else: "violated"
               )
           }
         ],
         %{}
       )}

  def opportunity_functions(s, source, lookback),
    do:
      {:ok,
       OrbitalDynamics.MissionAnalysis.Opportunity.Functions.from_evaluation(
         __MODULE__,
         s,
         source,
         lookback,
         [{"activity_type_available", "1", 0}]
       )}
end
