defmodule OrbitalDynamics.OperationalReadiness.OperationalModeGate do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.OperationalModeDecision

  def build(artifact, opts) do
    case OperationalModeDecision.decide(artifact, opts) do
      nil ->
        %{
          "id" => "operational_mode",
          "status" => "passed",
          "classification" => "importable",
          "reason" =>
            "artifact is not marked as simulation, rehearsal, trade study, or not-for-execution"
        }

      {mode, source, reason} ->
        %{
          "id" => "operational_mode",
          "status" => "analysis_only",
          "classification" => "analysis_only",
          "reason" => reason,
          "analysis_mode" => mode,
          "analysis_mode_source" => source
        }
    end
  end
end
