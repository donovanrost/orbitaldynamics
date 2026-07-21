defmodule OrbitalDynamics.Schema.CampaignRepairCommandWindowContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(issues, Map.get(artifact, "command_window_report"))
  end

  defp validate_report(issues, nil), do: issues
  defp validate_report(issues, :null), do: issues

  defp validate_report(issues, %{} = report) do
    issues
    |> validate_equal(
      "$.command_window_report.source",
      Map.get(report, "source"),
      "campaign_repair.activities",
      "must identify campaign_repair.activities"
    )
    |> validate_equal(
      "$.command_window_report.assumptions.source",
      assumption(report, "source"),
      "repaired campaign_repair.activities",
      "must identify repaired campaign_repair.activities"
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
