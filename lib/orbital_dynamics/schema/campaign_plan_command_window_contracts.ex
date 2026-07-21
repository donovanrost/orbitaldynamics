defmodule OrbitalDynamics.Schema.CampaignPlanCommandWindowContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(issues, Map.get(artifact, "command_window_report"))
  end

  defp validate_report(issues, nil), do: issues
  defp validate_report(issues, :null), do: issues

  defp validate_report(issues, report) when is_map(report) do
    issues
    |> validate_equal(
      "$.command_window_report.source",
      Map.get(report, "source"),
      "campaign_plan.activities",
      "must identify campaign_plan.activities"
    )
    |> validate_assumptions(report)
  end

  defp validate_report(issues, _report), do: issues

  defp validate_assumptions(issues, %{"assumptions" => assumptions})
       when is_map(assumptions) do
    issues
    |> validate_equal(
      "$.command_window_report.assumptions.source",
      Map.get(assumptions, "source"),
      "selected campaign_plan.activities",
      "must identify selected campaign_plan.activities"
    )
    |> validate_equal(
      "$.command_window_report.assumptions.boundary",
      Map.get(assumptions, "boundary"),
      "artifact_only_no_schedule_mutation_or_command_execution",
      "must preserve the artifact-only command boundary"
    )
  end

  defp validate_assumptions(issues, _report), do: issues

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
