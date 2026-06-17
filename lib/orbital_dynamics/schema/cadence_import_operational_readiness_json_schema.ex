defmodule OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  def context_properties do
    %{
      "ready_for_import_count" => non_negative_integer(),
      "manifest_review_required_count" => non_negative_integer(),
      "blocked_import_count" => non_negative_integer(),
      "missing_import_count" => non_negative_integer(),
      "invalid_cadence_import_count" => non_negative_integer(),
      "current_freshness_count" => non_negative_integer(),
      "stale_freshness_count" => non_negative_integer(),
      "unknown_freshness_count" => non_negative_integer(),
      "freshness_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "schema_validation_pass_count" => non_negative_integer(),
      "schema_validation_fail_count" => non_negative_integer(),
      "schema_validation_error_count" => non_negative_integer(),
      "schema_validation_warning_count" => non_negative_integer(),
      "schema_validation_remediation_count" => non_negative_integer(),
      "schema_validation_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "import_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "cadence_import_status_counts" => CommonJsonSchema.non_negative_integer_count_map()
    }
  end

  def evidence_properties(opts) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    %{
      "cadence_import_status" => status(),
      "readiness_level" => %{
        "type" => "string",
        "enum" => capability.readiness_levels
      },
      "import_classification" => %{
        "type" => "string",
        "enum" => capability.import_classifications
      },
      "operational_readiness_status" => %{
        "type" => "string",
        "enum" => capability.gate_statuses
      },
      "readiness_gate_id" => %{"type" => "string"},
      "readiness_gate_status" => %{
        "type" => "string",
        "enum" => capability.gate_statuses
      },
      "readiness_gate_classification" => %{
        "type" => "string",
        "enum" => capability.import_classifications
      },
      "readiness_gate_reason" => %{"type" => "string"},
      "gate_count" => non_negative_integer(),
      "passed_gate_count" => non_negative_integer(),
      "review_gate_count" => non_negative_integer(),
      "analysis_gate_count" => non_negative_integer(),
      "blocked_gate_count" => non_negative_integer(),
      "gates" => %{
        "type" => "array",
        "items" => opts.gate_schema
      },
      "evidence" => opts.evidence_schema,
      "source_operational_readiness_gate" => opts.gate_schema
    }
  end

  def status do
    %{
      "type" => "string",
      "enum" => OrbitalDynamics.CadenceImport.capability().cadence_import_statuses
    }
  end

  defp non_negative_integer do
    %{"type" => "integer", "minimum" => 0}
  end
end
