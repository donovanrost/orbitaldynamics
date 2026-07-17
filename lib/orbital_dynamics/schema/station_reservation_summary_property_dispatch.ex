defmodule OrbitalDynamics.Schema.StationReservationSummaryPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.StationReservationHoldImportReadinessSummaryJsonSchema
  alias OrbitalDynamics.Schema.StationReservationHoldSummaryJsonSchema
  alias OrbitalDynamics.Schema.StationReservationReviewSummaryJsonSchema

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
       when contract_name == contracts.review_summary do
    {
      &StationReservationReviewSummaryJsonSchema.property_field?/1,
      StationReservationReviewSummaryJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :review_row_schema),
        model_limits: Keyword.fetch!(deps, :model_limits),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.hold_summary do
    {
      &StationReservationHoldSummaryJsonSchema.property_field?/1,
      StationReservationHoldSummaryJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :review_row_schema),
        model_limits: Keyword.fetch!(deps, :model_limits),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.hold_import_readiness_summary do
    {
      &StationReservationHoldImportReadinessSummaryJsonSchema.property_field?/1,
      StationReservationHoldImportReadinessSummaryJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :import_readiness_row_schema),
        model_limits: Keyword.fetch!(deps, :model_limits),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end
end
