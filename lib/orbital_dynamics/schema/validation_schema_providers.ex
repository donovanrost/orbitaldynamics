defmodule OrbitalDynamics.Schema.ValidationSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts \\ [])
      when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:model_acceptance_row_json_schema, 0} => fn ->
        model_acceptance_row(stable_id_pattern)
      end,
      {:safety_case_evidence_row_json_schema, 0} => fn ->
        safety_case_evidence_row(stable_id_pattern)
      end,
      {:validation_record_json_schema, 0} => fn -> validation_record(stable_id_pattern) end,
      {:validation_reference_report_json_schema, 0} => fn ->
        validation_reference_report(stable_id_pattern)
      end,
      {:schema_validation_batch_entry_json_schema, 0} => fn ->
        dependencies
        |> Map.fetch!(:validation_report_schema)
        |> apply([])
        |> OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.batch_entry()
      end
    }
  end

  defp validation_record(stable_id_pattern) do
    OrbitalDynamics.Schema.ValidationJsonSchema.record(
      stable_id_pattern,
      OrbitalDynamics.Schema.ValidationJsonSchema.validation_level()
    )
  end

  defp model_acceptance_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ValidationJsonSchema.model_acceptance_row(
      stable_id_pattern,
      validation_record(stable_id_pattern)
    )
  end

  defp safety_case_evidence_row(stable_id_pattern) do
    OrbitalDynamics.Schema.ValidationJsonSchema.safety_case_evidence_row(stable_id_pattern)
  end

  defp validation_reference_report(stable_id_pattern) do
    OrbitalDynamics.Schema.ValidationJsonSchema.reference_report(
      stable_id_pattern,
      OrbitalDynamics.Schema.ValidationJsonSchema.validation_level(),
      OrbitalDynamics.Schema.ValidationJsonSchema.check()
    )
  end
end
