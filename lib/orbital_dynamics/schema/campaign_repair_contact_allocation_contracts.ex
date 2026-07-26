defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_report(Map.get(artifact, "contact_allocation_report"))
    |> validate_source_mirror(
      artifact,
      "source_contact_allocation_station_pressure_summary",
      "source_contact_allocation_station_pressure_summaries"
    )
    |> validate_source_mirror(
      artifact,
      "source_contact_allocation_reservation_conflict_summary",
      "source_contact_allocation_reservation_conflict_summaries"
    )
    |> validate_source_mirror(
      artifact,
      "source_contact_allocation_capacity_pack_summary",
      "source_contact_allocation_capacity_pack_summaries"
    )
  end

  defp validate_source_mirror(issues, artifact, singular_field, plural_field) do
    singular = Map.get(artifact, singular_field)
    plural = Map.get(artifact, plural_field)

    case {singular, plural} do
      {%{}, []} ->
        [source_mirror_error(singular_field, plural_field) | issues]

      {%{} = singular, [%{} = first | _summaries]} when singular != first ->
        [source_mirror_error(singular_field, plural_field) | issues]

      _fields ->
        issues
    end
  end

  defp source_mirror_error(singular_field, plural_field) do
    PrimitiveValidation.error(
      "$.#{singular_field}",
      "must equal $.#{plural_field}[0] when both fields are present"
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
