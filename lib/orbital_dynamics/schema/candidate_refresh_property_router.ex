defmodule OrbitalDynamics.Schema.CandidateRefreshPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "candidate_diff_report.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.diff_report(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      {fn -> provider(context, :source_window_lineage_json_schema, []) end,
       fn -> OrbitalDynamics.CandidateRefresh.model_limits() end,
       fn -> provider(context, :candidate_diff_row_json_schema, []) end,
       fn -> provider(context, :invalidated_candidate_json_schema, []) end}
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "candidate_diff_row.v1",
             "invalidated_candidate.v1",
             "source_window_lineage.v1"
           ] do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.diff_family(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      fn -> provider(context, :candidate_refresh_scoped_context_json_schema_properties, []) end
    )
  end

  def property(field, contract_name, contract, context)
      when contract_name in [
             "freshness_report.v1",
             "refresh_budget_report.v1",
             "refreshed_window.v1",
             "remaining_horizon.v1"
           ] do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.auxiliary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      context_value(context, :stable_id_pattern),
      fn -> OrbitalDynamics.CandidateRefresh.model_limits() end
    )
  end
end
