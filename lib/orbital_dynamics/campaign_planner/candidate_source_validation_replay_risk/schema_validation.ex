defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.SchemaValidation do
  @moduledoc false

  import OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.Common

  def risks(%{} = replay_summary) do
    if scoring_pressure?(replay_summary) do
      pressure_risk(replay_summary)
    else
      []
    end
  end

  def risks(_replay_summary), do: []

  defp scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_validation_pressure") == true or
      Map.get(replay_summary, "branch_local_schema_error_pressure") == true or
      Map.get(replay_summary, "branch_local_schema_warning_pressure") == true or
      Map.get(replay_summary, "branch_local_remediation_pressure") == true or
      summary_positive?(replay_summary, "error_count") or
      summary_positive?(replay_summary, "warning_count") or
      summary_positive?(replay_summary, "remediation_count")
  end

  defp pressure_risk(replay_summary) do
    statuses = pressure_statuses(replay_summary)

    validated_contracts =
      replay_summary |> Map.get("validated_contract_counts", %{}) |> map_keys()

    validation_modes = replay_summary |> Map.get("validation_mode_counts", %{}) |> map_keys()

    remediation_actions =
      replay_summary |> Map.get("remediation_action_counts", %{}) |> map_keys()

    remediation_categories =
      replay_summary |> Map.get("remediation_category_counts", %{}) |> map_keys()

    remediation_paths = replay_summary |> Map.get("remediation_path_counts", %{}) |> map_keys()

    issue_severity =
      cond do
        summary_positive?(replay_summary, "error_count") -> "error"
        summary_positive?(replay_summary, "warning_count") -> "warning"
        true -> nil
      end

    [
      %{
        "type" => "schema_validation_pressure",
        "severity" =>
          pressure_risk_severity(%{
            "validation_status" => pressure_priority_value(statuses),
            "issue_severity" => issue_severity,
            "required_operator_action" => "review_schema_validation"
          }),
        "reason" =>
          "candidate source schema-validation replay reports failing, warning, or remediation pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "status_counts" => Map.get(replay_summary, "status_counts"),
        "validated_contract_counts" => Map.get(replay_summary, "validated_contract_counts"),
        "validation_mode_counts" => Map.get(replay_summary, "validation_mode_counts"),
        "error_count" => Map.get(replay_summary, "error_count"),
        "warning_count" => Map.get(replay_summary, "warning_count"),
        "remediation_count" => Map.get(replay_summary, "remediation_count"),
        "remediation_action_counts" => Map.get(replay_summary, "remediation_action_counts"),
        "remediation_category_counts" => Map.get(replay_summary, "remediation_category_counts"),
        "remediation_path_counts" => Map.get(replay_summary, "remediation_path_counts"),
        "validation_status" => pressure_priority_value(statuses),
        "validation_statuses" => statuses,
        "validation_mode" => pressure_priority_value(validation_modes),
        "validation_modes" => validation_modes,
        "validated_contract" => pressure_priority_value(validated_contracts),
        "validated_contracts" => validated_contracts,
        "issue_severity" => issue_severity,
        "remediation_action" => pressure_priority_value(remediation_actions),
        "remediation_actions" => remediation_actions,
        "remediation_category" => pressure_priority_value(remediation_categories),
        "remediation_categories" => remediation_categories,
        "remediation_paths" => remediation_paths,
        "branch_local_validation_pressure" =>
          Map.get(replay_summary, "branch_local_validation_pressure"),
        "branch_local_schema_error_pressure" =>
          Map.get(replay_summary, "branch_local_schema_error_pressure"),
        "branch_local_schema_warning_pressure" =>
          Map.get(replay_summary, "branch_local_schema_warning_pressure"),
        "branch_local_remediation_pressure" =>
          Map.get(replay_summary, "branch_local_remediation_pressure"),
        "feedback_source" => "candidate_source.schema_validation_replay_summary",
        "feedback_scope" => "schema_validation",
        "feedback_key" => "schema_validation",
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp pressure_statuses(replay_summary) do
    count_statuses =
      [
        {"error_count", "fail"},
        {"warning_count", "warning"},
        {"remediation_count", "warning"}
      ]
      |> Enum.flat_map(fn {field, status} ->
        if summary_positive?(replay_summary, field), do: [status], else: []
      end)

    [
      replay_summary |> Map.get("status_counts", %{}) |> map_keys(),
      count_statuses
    ]
    |> sorted_encoded_values()
  end
end
