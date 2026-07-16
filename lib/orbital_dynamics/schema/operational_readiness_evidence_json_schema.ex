defmodule OrbitalDynamics.Schema.OperationalReadinessEvidenceJsonSchema do
  @moduledoc false

  @count_fields [
    "review_row_count",
    "import_row_count",
    "review_required_count",
    "blocked_review_count",
    "ready_for_import_count",
    "manifest_review_required_count",
    "blocked_import_count",
    "missing_import_count",
    "invalid_cadence_import_count",
    "current_freshness_count",
    "stale_freshness_count",
    "unknown_freshness_count",
    "schema_validation_pass_count",
    "schema_validation_fail_count",
    "schema_validation_error_count",
    "schema_validation_warning_count",
    "schema_validation_remediation_count",
    "source_model_count",
    "source_model_limit_count",
    "policy_decision_count",
    "policy_auto_approvable_count",
    "policy_review_required_count",
    "policy_blocked_count",
    "adapter_context_count",
    "adapter_trust_boundary_declared_count",
    "adapter_trust_boundary_missing_count",
    "adapter_trust_boundary_untrusted_count",
    "operator_training_requirement_count",
    "resource_availability_pressure_count",
    "resource_blocking_dimension_count"
  ]

  @count_map_fields [
    "review_type_counts",
    "approval_status_counts",
    "import_action_counts",
    "source_review_type_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "freshness_status_counts",
    "schema_validation_status_counts",
    "source_model_counts",
    "source_model_limit_counts",
    "policy_classification_counts",
    "operator_training_requirement_counts",
    "resource_availability_reason_counts",
    "station_availability_reason_counts",
    "resource_blocking_dimension_counts",
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts"
  ]

  @string_array_fields [
    "required_operator_roles",
    "required_training_ids",
    "required_certification_ids",
    "required_qualification_ids",
    "resource_availability_reason_ids",
    "station_availability_reason_ids",
    "unavailable_resource_reason_ids"
  ]

  def schema(opts) do
    properties =
      @count_fields
      |> Map.new(&{&1, %{"type" => "integer", "minimum" => 0}})
      |> Map.merge(count_map_properties(opts))
      |> Map.merge(string_array_properties(opts))
      |> Map.merge(%{
        "adapter_boundary_status_counts" =>
          Keyword.fetch!(opts, :branch_event_trust_boundary_status_counts_schema),
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "type" => "object",
          "additionalProperties" => Keyword.fetch!(opts, :stable_id_array_schema)
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "type" => "object",
          "additionalProperties" => Keyword.fetch!(opts, :stable_id_array_schema)
        }
      })
      |> Map.merge(Keyword.fetch!(opts, :timeline_publication_context_properties))

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => properties
    }
  end

  defp count_map_properties(opts) do
    count_map_schema = Keyword.fetch!(opts, :count_map_schema)

    Map.new(@count_map_fields, &{&1, count_map_schema})
  end

  defp string_array_properties(opts) do
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)

    Map.new(@string_array_fields, &{&1, string_array_schema})
  end
end
