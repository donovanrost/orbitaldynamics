defmodule OrbitalDynamics.Schema.CampaignPlanConstraintContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(issues, Map.get(artifact, "constraint_report"))
  end

  defp validate_report(issues, nil), do: issues
  defp validate_report(issues, :null), do: issues

  defp validate_report(issues, report) when is_map(report) do
    issues
    |> validate_equal(
      "$.constraint_report.model",
      Map.get(report, "model"),
      "campaign_planner_local_constraint_summary",
      "must identify the V1 campaign constraint model"
    )
    |> validate_equal(
      "$.constraint_report.assumptions.constraint_model",
      assumption(report, "constraint_model"),
      "campaign_v1_planner_local_constraints",
      "must identify the V1 campaign constraint assumptions"
    )
    |> validate_equal(
      "$.constraint_report.assumptions.source",
      assumption(report, "source"),
      "campaign_plan.assumptions.constraints",
      "must identify campaign_plan.assumptions.constraints"
    )
  end

  defp validate_report(issues, _report), do: issues

  defp assumption(%{"assumptions" => assumptions}, field) when is_map(assumptions),
    do: Map.get(assumptions, field)

  defp assumption(_report, _field), do: nil

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
