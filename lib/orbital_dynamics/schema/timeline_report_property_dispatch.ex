defmodule OrbitalDynamics.Schema.TimelineReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema
  alias OrbitalDynamics.Schema.TimelineDiffReportJsonSchema
  alias OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)

    {property_field?, property} =
      property_dispatch(contract_name, contracts, deps)

    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.operational_timeline_report do
    {
      &OperationalTimelineReportJsonSchema.property_field?/1,
      OperationalTimelineReportJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        row_schema: Keyword.fetch!(deps, :operational_timeline_row_schema),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        capability: Keyword.fetch!(deps, :capability)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.timeline_diff_report do
    {
      &TimelineDiffReportJsonSchema.property_field?/1,
      TimelineDiffReportJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        row_schema: Keyword.fetch!(deps, :timeline_diff_row_schema),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        capability: Keyword.fetch!(deps, :capability)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.timeline_diff_summary do
    {
      &TimelineDiffSummaryJsonSchema.property_field?/1,
      TimelineDiffSummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        row_schema: Keyword.fetch!(deps, :timeline_diff_row_schema),
        capability: Keyword.fetch!(deps, :capability),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end
end
