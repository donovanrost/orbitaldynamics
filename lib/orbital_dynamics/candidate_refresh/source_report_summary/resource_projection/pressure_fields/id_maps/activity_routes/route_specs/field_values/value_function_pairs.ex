defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.ValueFunctionPairs do
  @moduledoc false

  alias __MODULE__.PairDispatch
  alias __MODULE__.ValueLookups

  def by_status(field, source_activity_ids_fun) do
    PairDispatch.from_value_fun(field, ValueLookups.by_status(field, source_activity_ids_fun))
  end

  def by_type(field, source_activity_ids_fun) do
    PairDispatch.from_value_fun(field, ValueLookups.by_type(field, source_activity_ids_fun))
  end

  def by_key(field, key_fun, source_activity_ids_fun) do
    PairDispatch.from_value_fun(
      field,
      ValueLookups.by_key(field, key_fun, source_activity_ids_fun)
    )
  end
end
