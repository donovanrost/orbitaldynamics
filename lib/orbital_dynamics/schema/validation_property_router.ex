defmodule OrbitalDynamics.Schema.ValidationPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(
        field,
        contract_name,
        contract,
        context
      )
      when contract_name in [
             "validation_reference_fixture_report.v1",
             "validation_reference_report.v1",
             "validation_record.v1",
             "validation_check.v1"
           ] do
    OrbitalDynamics.Schema.ValidationEvidencePropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        reference_fixture_report: "validation_reference_fixture_report.v1",
        reference_report: "validation_reference_report.v1",
        record: "validation_record.v1",
        check: "validation_check.v1"
      },
      reference_report_schema: fn ->
        provider(context, :validation_reference_report_json_schema, [])
      end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      validation_check_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.check/0,
      validation_level_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.validation_level/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["model_acceptance_report.v1", "validation_safety_case_summary.v1"] do
    OrbitalDynamics.Schema.ValidationAssessmentPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        model_acceptance_report: "model_acceptance_report.v1",
        validation_safety_case_summary: "validation_safety_case_summary.v1"
      },
      model_limits: fn -> provider(context, :model_acceptance_report_model_limits, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      validation_record_schema: fn -> provider(context, :validation_record_json_schema, []) end,
      model_acceptance_row_schema: fn ->
        provider(context, :model_acceptance_row_json_schema, [])
      end,
      safety_case_evidence_row_schema: fn ->
        provider(context, :safety_case_evidence_row_json_schema, [])
      end,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(
        "implementation_tiers",
        "backend_acceptance_policy.v1",
        _contract,
        _context
      ) do
    %{
      "type" => "object",
      "propertyNames" => %{
        "pattern" => OrbitalDynamics.Validation.ImplementationKey.pattern()
      },
      "additionalProperties" => %{"type" => "string"}
    }
  end

  def property("reference_backend", "backend_acceptance_policy.v1", _contract, _context) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "implementations" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "pattern" => OrbitalDynamics.Validation.ImplementationKey.pattern()
          }
        }
      }
    }
  end

  def property(field, "backend_acceptance_policy.v1" = contract_name, contract, context) do
    fallback(field, contract_name, contract, context)
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["schema_validation_report.v1", "schema_validation_batch_report.v1"] do
    OrbitalDynamics.Schema.SchemaValidationPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: "schema_validation_report.v1",
        batch: "schema_validation_batch_report.v1"
      },
      issue_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.issue/0,
      remediation_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.remediation/0,
      model_limits: fn -> provider(context, :schema_validation_model_limits, []) end,
      batch_entry_schema: fn ->
        provider(context, :schema_validation_batch_entry_json_schema, [])
      end,
      skipped_artifact_schema:
        &OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.skipped_artifact/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "schema_migration_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.SchemaValidationPropertyDispatch.migration(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"schema_migration_report.v1", 1,
       fn -> provider(context, :schema_migration_statuses, []) end,
       fn -> provider(context, :schema_migration_row_statuses, []) end,
       &OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema.row/0,
       &OrbitalDynamics.Schema.SchemaMigrationContracts.model_limits/0}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in ["campaign_request_lint.v1", "study_manifest_lint.v1"] do
    OrbitalDynamics.Schema.LintReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        campaign_request: "campaign_request_lint.v1",
        study_manifest: "study_manifest_lint.v1"
      },
      validation_issue_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.issue/0,
      sha256_schema: fn -> provider(context, :sha256_json_schema, []) end,
      stable_id_pattern: context_value(context, :stable_id_pattern),
      manifest_lint_issue_schema:
        &OrbitalDynamics.Schema.ValidationJsonSchema.manifest_lint_issue/0,
      default_property: fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end
end
