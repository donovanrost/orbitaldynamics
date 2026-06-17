defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.ValidationSafetyCase do
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
    Map.get(replay_summary, "branch_local_review_pressure") == true or
      Map.get(replay_summary, "branch_local_blocking_pressure") == true or
      Map.get(replay_summary, "branch_local_schema_pressure") == true or
      Map.get(replay_summary, "branch_local_fixture_pressure") == true or
      summary_positive?(replay_summary, "review_required_evidence_count") or
      summary_positive?(replay_summary, "blocked_evidence_count") or
      summary_positive?(replay_summary, "schema_error_count") or
      summary_positive?(replay_summary, "schema_warning_count") or
      summary_positive?(replay_summary, "model_blocked_count") or
      summary_positive?(replay_summary, "quality_gate_review_count") or
      summary_positive?(replay_summary, "quality_gate_blocked_count")
  end

  defp pressure_risk(replay_summary) do
    safety_case_statuses = replay_summary |> Map.get("status_counts", %{}) |> map_keys()
    evidence_statuses = replay_summary |> Map.get("evidence_status_counts", %{}) |> map_keys()
    input_contracts = replay_summary |> Map.get("input_contract_counts", %{}) |> map_keys()

    pressure_statuses =
      if Enum.any?(safety_case_statuses, &(&1 in ["blocked", "review_required"])) do
        safety_case_statuses
      else
        case evidence_statuses do
          [] -> safety_case_statuses
          statuses -> statuses
        end
      end

    evidence_refs =
      [
        replay_summary |> Map.get("evidence_refs_by_status", %{}) |> Map.values(),
        replay_summary |> Map.get("evidence_refs_by_contract", %{}) |> Map.values()
      ]
      |> List.flatten()
      |> sorted_encoded_values()

    blocked? =
      "blocked" in safety_case_statuses or "blocked" in evidence_statuses or
        summary_positive?(replay_summary, "blocked_evidence_count")

    [
      %{
        "type" => "validation_safety_case_pressure",
        "severity" =>
          pressure_risk_severity(%{
            "validation_safety_case_status" => pressure_priority_value(pressure_statuses),
            "evidence_status" => pressure_priority_value(evidence_statuses),
            "required_operator_action" =>
              if(blocked?,
                do: "review_blocked_validation_safety_case",
                else: "review_validation_safety_case"
              )
          }),
        "reason" =>
          "candidate source validation-safety-case replay reports review, blocking, schema, model, readiness, or quality-gate pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "validation_safety_case_status" => pressure_priority_value(pressure_statuses),
        "validation_safety_case_statuses" => pressure_statuses,
        "evidence_status" => pressure_priority_value(evidence_statuses),
        "evidence_statuses" => evidence_statuses,
        "input_contract" => pressure_priority_value(input_contracts),
        "input_contracts" => input_contracts,
        "evidence_refs" => evidence_refs,
        "status_counts" => Map.get(replay_summary, "status_counts"),
        "evidence_status_counts" => Map.get(replay_summary, "evidence_status_counts"),
        "input_contract_counts" => Map.get(replay_summary, "input_contract_counts"),
        "evidence_refs_by_status" => Map.get(replay_summary, "evidence_refs_by_status"),
        "evidence_refs_by_contract" => Map.get(replay_summary, "evidence_refs_by_contract"),
        "accepted_evidence_count" => Map.get(replay_summary, "accepted_evidence_count"),
        "review_required_evidence_count" =>
          Map.get(replay_summary, "review_required_evidence_count"),
        "blocked_evidence_count" => Map.get(replay_summary, "blocked_evidence_count"),
        "model_blocked_count" => Map.get(replay_summary, "model_blocked_count"),
        "quality_gate_review_count" => Map.get(replay_summary, "quality_gate_review_count"),
        "quality_gate_blocked_count" => Map.get(replay_summary, "quality_gate_blocked_count"),
        "schema_error_count" => Map.get(replay_summary, "schema_error_count"),
        "schema_warning_count" => Map.get(replay_summary, "schema_warning_count"),
        "branch_local_review_pressure" => Map.get(replay_summary, "branch_local_review_pressure"),
        "branch_local_blocking_pressure" =>
          Map.get(replay_summary, "branch_local_blocking_pressure"),
        "branch_local_schema_pressure" => Map.get(replay_summary, "branch_local_schema_pressure"),
        "branch_local_fixture_pressure" =>
          Map.get(replay_summary, "branch_local_fixture_pressure"),
        "feedback_source" => "candidate_source.validation_safety_case_replay_summary",
        "feedback_scope" => "validation_safety_case",
        "feedback_key" => "validation_safety_case",
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end
end
