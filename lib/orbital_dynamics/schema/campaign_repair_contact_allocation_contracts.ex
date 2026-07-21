defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(issues, Map.get(artifact, "contact_allocation_report"))
  end

  defp validate_report(issues, nil), do: issues
  defp validate_report(issues, :null), do: issues

  defp validate_report(issues, %{} = report) do
    if Map.get(report, "source") == "campaign_repair.activities" do
      issues
    else
      [
        PrimitiveValidation.error(
          "$.contact_allocation_report.source",
          "must identify campaign_repair.activities"
        )
        | issues
      ]
    end
  end

  defp validate_report(issues, _report), do: issues
end
