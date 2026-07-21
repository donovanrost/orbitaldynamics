defmodule OrbitalDynamics.Schema.CampaignPlanContactAllocationContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(issues, Map.get(artifact, "contact_allocation_report"))
  end

  defp validate_report(issues, nil), do: issues
  defp validate_report(issues, :null), do: issues

  defp validate_report(issues, report) when is_map(report) do
    issues
    |> validate_equal(
      "$.contact_allocation_report.model",
      Map.get(report, "model"),
      "deterministic_station_contact_allocation",
      "must identify the V1 contact allocation model"
    )
    |> validate_equal(
      "$.contact_allocation_report.source",
      Map.get(report, "source"),
      "campaign_plan.candidate_activities",
      "must identify campaign_plan.candidate_activities"
    )
  end

  defp validate_report(issues, _report), do: issues

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
