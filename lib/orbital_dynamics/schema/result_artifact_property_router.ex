defmodule OrbitalDynamics.Schema.ResultArtifactPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4]

  def property(
        field,
        "execution_report.v1" = contract_name,
        contract,
        context,
        _embedded_fun
      ) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.execution_report(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"execution_report.v1", context_value(context, :stable_id_pattern),
       &OrbitalDynamics.ResultSet.Artifact.execution_report_model_limit_values/0}
    )
  end

  def property(
        field,
        "result_artifact.v1" = contract_name,
        contract,
        context,
        embedded_fun
      ) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.result_artifact(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {1, context_value(context, :stable_id_pattern), "execution_report.v1", embedded_fun}
    )
  end

  def property(
        field,
        "resource_summary.v1" = contract_name,
        contract,
        context,
        _embedded_fun
      ) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.resource_summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"resource_summary.v1", context_value(context, :stable_id_pattern)}
    )
  end
end
