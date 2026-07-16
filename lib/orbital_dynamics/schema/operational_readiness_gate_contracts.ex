defmodule OrbitalDynamics.Schema.OperationalReadinessGateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_one_of: 5,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4
    ]

  alias OrbitalDynamics.Schema.OperationalReadinessContextContracts

  def validate(issues, path, gate, timeline_publication_validator) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> require_fields(path, gate, ["id", "status", "classification", "reason"])
    |> expect_one_of(path, gate, "id", capability.gates)
    |> expect_one_of(path, gate, "status", capability.gate_statuses)
    |> expect_one_of(path, gate, "classification", capability.import_classifications)
    |> expect_type(path, gate, "reason", :binary)
    |> expect_optional_one_of(path, gate, "analysis_mode", capability.analysis_modes)
    |> expect_optional_type(path, gate, "analysis_mode_source", :binary)
    |> OperationalReadinessContextContracts.validate_resource_context(path, gate)
    |> OperationalReadinessContextContracts.validate_operator_training_context(path, gate)
    |> OperationalReadinessContextContracts.validate_adapter_boundary_context(path, gate)
    |> OperationalReadinessContextContracts.validate_cadence_import_context(path, gate)
    |> timeline_publication_validator.(path, gate)
  end
end
