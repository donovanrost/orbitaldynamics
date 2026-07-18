defmodule OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CommandWindowReportJsonSchema,
    StationCalendarPrecedenceSummaryJsonSchema,
    StationCalendarReportJsonSchema,
    StationReservationReportJsonSchema
  }

  def command_window(
        field,
        contract_name,
        contract,
        default_property,
        {model_limits, row_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CommandWindowReportJsonSchema.property_field?/1,
      CommandWindowReportJsonSchema.property_fun_from_context(
        model_limits: model_limits,
        row_schema: row_schema
      ),
      default_property
    )
  end

  def calendar_precedence(
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
      &StationCalendarPrecedenceSummaryJsonSchema.property_field?/1,
      StationCalendarPrecedenceSummaryJsonSchema.property_fun_from_context(
        model_limits: model_limits,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  def reservation(
        field,
        contract_name,
        contract,
        default_property,
        stable_id_pattern,
        {models, contact_schema, provider_contention_group_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &StationReservationReportJsonSchema.property_field?/1,
      StationReservationReportJsonSchema.property_fun_from_context(
        models: models,
        contact_schema: contact_schema,
        provider_contention_group_schema: provider_contention_group_schema,
        stable_id_pattern: stable_id_pattern
      ),
      default_property
    )
  end

  def calendar(
        field,
        contract_name,
        contract,
        default_property,
        {
          contact_schema,
          model,
          provider_contention_group_schema,
          entry_schema,
          trust_boundary_status_count_schema,
          model_limits
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &StationCalendarReportJsonSchema.property_field?/1,
      StationCalendarReportJsonSchema.property_fun_from_context(
        contact_schema: contact_schema,
        model: model,
        provider_contention_group_schema: provider_contention_group_schema,
        entry_schema: entry_schema,
        trust_boundary_status_count_schema: trust_boundary_status_count_schema,
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
