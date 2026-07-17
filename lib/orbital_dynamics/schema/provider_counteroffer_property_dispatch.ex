defmodule OrbitalDynamics.Schema.ProviderCounterofferPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.Schema.ProviderCounterofferImportReadinessSummaryJsonSchema
  alias OrbitalDynamics.Schema.ProviderCounterofferPlanImpactSummaryJsonSchema
  alias OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema
  alias OrbitalDynamics.Schema.ProviderCounterofferReviewSummaryJsonSchema

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
       when contract_name == contracts.report do
    {
      &ProviderCounterofferReportJsonSchema.property_field?/1,
      ProviderCounterofferReportJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :row_schema),
        models: Keyword.fetch!(deps, :models),
        negotiation_states: fn ->
          StationCalendar.capabilities().provider_counteroffer_negotiation_states
        end,
        operator_actions: fn ->
          StationCalendar.capabilities().provider_counteroffer_actions
        end
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.review_summary do
    {
      &ProviderCounterofferReviewSummaryJsonSchema.property_field?/1,
      ProviderCounterofferReviewSummaryJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :row_schema),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.import_readiness_summary do
    {
      &ProviderCounterofferImportReadinessSummaryJsonSchema.property_field?/1,
      ProviderCounterofferImportReadinessSummaryJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :row_schema),
        readiness_statuses: fn ->
          StationCalendar.capabilities().provider_counteroffer_import_readiness_statuses
        end,
        import_classifications: fn ->
          StationCalendar.capabilities().provider_counteroffer_import_classifications
        end,
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.plan_impact_summary do
    {
      &ProviderCounterofferPlanImpactSummaryJsonSchema.property_field?/1,
      ProviderCounterofferPlanImpactSummaryJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :row_schema),
        plan_impact_statuses: fn ->
          StationCalendar.capabilities().provider_counteroffer_plan_impact_statuses
        end,
        lock_deadline_statuses: fn ->
          StationCalendar.capabilities().provider_counteroffer_lock_deadline_statuses
        end,
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end
end
