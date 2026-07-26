defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_report(Map.get(artifact, "contact_allocation_report"))
    |> validate_capacity_pack_source_mirror(artifact)
  end

  defp validate_capacity_pack_source_mirror(issues, artifact) do
    singular = Map.get(artifact, "source_contact_allocation_capacity_pack_summary")
    plural = Map.get(artifact, "source_contact_allocation_capacity_pack_summaries")

    case {singular, plural} do
      {%{}, []} ->
        [capacity_pack_source_mirror_error() | issues]

      {%{} = singular, [%{} = first | _summaries]} when singular != first ->
        [capacity_pack_source_mirror_error() | issues]

      _fields ->
        issues
    end
  end

  defp capacity_pack_source_mirror_error do
    PrimitiveValidation.error(
      "$.source_contact_allocation_capacity_pack_summary",
      "must equal $.source_contact_allocation_capacity_pack_summaries[0] when both fields are present"
    )
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
