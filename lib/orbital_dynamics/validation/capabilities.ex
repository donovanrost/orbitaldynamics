defmodule OrbitalDynamics.Validation.Capabilities do
  @moduledoc false

  def build(context) when is_map(context) do
    [model_acceptance_contract, safety_case_contract, schema_migration_contract] =
      context.schema_contracts

    %{
      schema_contracts: [
        model_acceptance_contract,
        safety_case_contract,
        "validation_reference_fixture_report.v1",
        "validation_reference_report.v1",
        "validation_check.v1",
        "validation_record.v1",
        "validation_tolerance_policy.v1",
        "backend_acceptance_policy.v1",
        schema_migration_contract
      ],
      intended_uses: context.intended_uses,
      acceptance_statuses: context.acceptance_statuses,
      row_statuses: context.row_statuses,
      safety_case_statuses: context.safety_case_statuses,
      schema_migration_statuses: context.schema_migration_statuses,
      schema_migration_row_statuses: context.schema_migration_row_statuses,
      schema_migration_actions: context.schema_migration_actions,
      summary_semantics: [
        :model_acceptance_status_counts,
        :model_acceptance_model_ids_by_status,
        :model_acceptance_model_ids_by_validation_level,
        :model_acceptance_model_ids_by_intended_use,
        :validation_safety_case_evidence_status_counts,
        :validation_safety_case_evidence_refs_by_status,
        :validation_safety_case_evidence_refs_by_contract,
        :schema_migration_status_counts,
        :schema_migration_action_counts,
        :schema_migration_deprecation_warning_counts
      ],
      safety_case_evidence_semantics: [
        :validation_safety_case_model_count_rollups,
        :validation_safety_case_model_acceptance_row_status_floor,
        :validation_safety_case_readiness_count_rollups,
        :validation_safety_case_readiness_gate_status_floor,
        :validation_safety_case_quality_gate_count_rollups,
        :validation_safety_case_quality_gate_row_status_floor,
        :validation_safety_case_schema_validation_count_rollups,
        :validation_safety_case_schema_validation_issue_list_floor,
        :validation_safety_case_schema_validation_batch_nested_status_floor,
        :validation_safety_case_fixture_count_rollups,
        :validation_safety_case_fixture_nested_status_floor,
        :validation_safety_case_review_import_handoff_evidence,
        :validation_safety_case_input_contract_routing,
        :validation_safety_case_status_ref_routing,
        :validation_safety_case_contract_ref_routing
      ],
      validation_levels:
        context.tolerance_policy.()["validation_levels"] |> Map.keys() |> Enum.sort(),
      public_facades: [
        :validation_safety_case_summary,
        :validation_model_acceptance_report,
        :validation_registry,
        :validation_record,
        :validation_records_for_result_set,
        :validation_tolerance_policy,
        :backend_acceptance_policy,
        :backend_acceptance_evidence,
        :validation_schema_migration_report,
        :validation_reference_fixtures,
        :validation_reference_fixture,
        :verify_validation_reference_fixture,
        :validation_reference_fixture_report
      ],
      known_limits: [
        "acceptance is evidence-based and not flight certification",
        "unknown models are blocked until registered validation evidence exists",
        "operational import acceptance remains artifact-only and requires downstream operator policy"
      ]
    }
  end
end
