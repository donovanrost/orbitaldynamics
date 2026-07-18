defmodule OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CandidateDiffJsonSchema,
    CandidateRefreshReportJsonSchema
  }

  def diff_report(
        field,
        contract_name,
        contract,
        default_property,
        stable_id_pattern,
        {
          source_window_lineage_schema,
          model_limits,
          candidate_diff_row_schema,
          invalidated_candidate_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CandidateDiffJsonSchema.report_property_field?/1,
      CandidateDiffJsonSchema.report_property_fun_from_context(
        source_window_lineage_schema: source_window_lineage_schema,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits,
        candidate_diff_row_schema: candidate_diff_row_schema,
        invalidated_candidate_schema: invalidated_candidate_schema
      ),
      default_property
    )
  end

  def diff_family(
        field,
        contract_name,
        contract,
        default_property,
        stable_id_pattern,
        scoped_context_properties
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CandidateDiffJsonSchema.family_property_field?(&1, contract_name),
      CandidateDiffJsonSchema.family_property_fun_from_context(
        contract_name: contract_name,
        stable_id_pattern: stable_id_pattern,
        scoped_context_properties: scoped_context_properties
      ),
      default_property
    )
  end

  def auxiliary(
        field,
        contract_name,
        contract,
        default_property,
        stable_id_pattern,
        model_limits
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CandidateRefreshReportJsonSchema.auxiliary_report_property_field?(&1, contract_name),
      CandidateRefreshReportJsonSchema.auxiliary_report_property_fun_from_context(
        contract_name: contract_name,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits
      ),
      default_property
    )
  end

  defp dispatch(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         default_property
       ) do
    if property_field?.(field) do
      property.(field)
    else
      default_property.(field, contract_name, contract)
    end
  end
end
