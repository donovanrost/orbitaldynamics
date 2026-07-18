defmodule OrbitalDynamics.Schema.SchemaValidationPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    SchemaMigrationReportJsonSchema,
    SchemaValidationReportJsonSchema
  }

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)
    kind = kind(contract_name, contracts)

    focused_property(
      field,
      contract_name,
      contract,
      &SchemaValidationReportJsonSchema.property_field?(&1, kind),
      SchemaValidationReportJsonSchema.property_fun_from_context(
        kind,
        schema_contract: fn
          :report -> contracts.report
          :batch -> contracts.batch
        end,
        issue_schema: Keyword.fetch!(deps, :issue_schema),
        remediation_schema: Keyword.fetch!(deps, :remediation_schema),
        model_limits: Keyword.fetch!(deps, :model_limits),
        batch_entry_schema: Keyword.fetch!(deps, :batch_entry_schema),
        skipped_artifact_schema: Keyword.fetch!(deps, :skipped_artifact_schema)
      ),
      deps
    )
  end

  def migration(
        field,
        contract_name,
        contract,
        default_property,
        {
          schema_contract,
          schema_version,
          schema_migration_statuses,
          schema_migration_row_statuses,
          row_schema,
          model_limits
        }
      ) do
    focused_property(
      field,
      contract_name,
      contract,
      &SchemaMigrationReportJsonSchema.property_field?/1,
      SchemaMigrationReportJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        schema_version: schema_version,
        schema_migration_statuses: schema_migration_statuses,
        schema_migration_row_statuses: schema_migration_row_statuses,
        row_schema: row_schema,
        model_limits: model_limits
      ),
      default_property: default_property
    )
  end

  defp kind(contract_name, contracts) when contract_name == contracts.report, do: :report
  defp kind(contract_name, contracts) when contract_name == contracts.batch, do: :batch

  defp focused_property(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         deps
       ) do
    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end
end
