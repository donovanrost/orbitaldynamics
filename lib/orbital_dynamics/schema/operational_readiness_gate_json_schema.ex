defmodule OrbitalDynamics.Schema.OperationalReadinessGateJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema
  alias OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema

  def gate(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "status", "classification", "reason"],
      "properties" => gate_properties(opts)
    }
  end

  defp gate_properties(opts) do
    capability = Keyword.fetch!(opts, :capability)
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "id" => %{"type" => "string", "enum" => capability.gates},
      "status" => %{"type" => "string", "enum" => capability.gate_statuses},
      "classification" => %{
        "type" => "string",
        "enum" => capability.import_classifications
      },
      "reason" => %{"type" => "string"},
      "analysis_mode" => %{"type" => "string", "enum" => capability.analysis_modes},
      "analysis_mode_source" => %{"type" => "string"}
    }
    |> Map.merge(
      OperationalReadinessContextJsonSchema.resource_context_properties(
        stable_id_pattern: stable_id_pattern
      )
    )
    |> Map.merge(OperationalReadinessContextJsonSchema.operator_training_context_properties())
    |> Map.merge(OperationalReadinessContextJsonSchema.cadence_import_context_properties())
    |> Map.merge(
      CandidateRefreshReportJsonSchema.timeline_publication_context_properties(
        stable_id_pattern: stable_id_pattern
      )
    )
  end
end
