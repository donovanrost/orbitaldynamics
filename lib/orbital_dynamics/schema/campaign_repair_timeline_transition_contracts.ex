defmodule OrbitalDynamics.Schema.CampaignRepairTimelineTransitionContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(
      issues,
      artifact,
      Map.get(artifact, "timeline_transition_application_report")
    )
  end

  defp validate_report(issues, _artifact, nil), do: issues
  defp validate_report(issues, _artifact, :null), do: issues

  defp validate_report(issues, artifact, %{} = report) do
    repair_metadata = Map.get(artifact, "repair_metadata", %{})

    issues
    |> validate_equal(
      "$.timeline_transition_application_report.source",
      Map.get(report, "source"),
      "campaign_repair.timeline_transition_application",
      "must identify the V2 repair timeline transition source"
    )
    |> validate_equal(
      "$.timeline_transition_application_report.replacement_activity_count",
      Map.get(report, "replacement_activity_count"),
      artifact |> Map.get("activities", []) |> List.wrap() |> length(),
      "must match enclosing repaired activity count"
    )
    |> validate_equal(
      "$.repair_metadata.transition_selected_activity_count",
      metadata_value(repair_metadata, "transition_selected_activity_count"),
      Map.get(report, "selected_activity_count"),
      "must match timeline transition selected activity count"
    )
    |> validate_equal(
      "$.repair_metadata.transition_application_review_required_count",
      metadata_value(repair_metadata, "transition_application_review_required_count"),
      Map.get(report, "review_required_count"),
      "must match timeline transition review-required count"
    )
  end

  defp validate_report(issues, _artifact, _report), do: issues

  defp metadata_value(metadata, field) when is_map(metadata), do: Map.get(metadata, field)
  defp metadata_value(_metadata, _field), do: nil

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
