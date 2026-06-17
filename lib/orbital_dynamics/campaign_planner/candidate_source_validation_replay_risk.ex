defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.{
    Freshness,
    ModelAcceptance,
    RefreshBudget,
    SchemaValidation,
    ValidationSafetyCase
  }

  import OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.Common

  def quality_gate(%{} = replay_summary) do
    if quality_gate_scoring_pressure?(replay_summary) do
      quality_gate_pressure_risk(replay_summary)
    else
      []
    end
  end

  def quality_gate(_replay_summary), do: []

  def schema_validation(%{} = replay_summary) do
    SchemaValidation.risks(replay_summary)
  end

  def schema_validation(_replay_summary), do: []

  def freshness(%{} = replay_summary) do
    Freshness.risks(replay_summary)
  end

  def freshness(_replay_summary), do: []

  def refresh_budget(%{} = replay_summary) do
    RefreshBudget.risks(replay_summary)
  end

  def refresh_budget(_replay_summary), do: []

  def validation_safety_case(%{} = replay_summary) do
    ValidationSafetyCase.risks(replay_summary)
  end

  def validation_safety_case(_replay_summary), do: []

  def model_acceptance(%{} = replay_summary) do
    ModelAcceptance.risks(replay_summary)
  end

  def model_acceptance(_replay_summary), do: []

  defp quality_gate_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_review_pressure") == true or
      Map.get(replay_summary, "branch_local_import_pressure") == true or
      summary_positive?(replay_summary, "review_gate_count") or
      summary_positive?(replay_summary, "blocked_gate_count") or
      summary_positive?(replay_summary, "non_passed_gate_count")
  end

  defp quality_gate_pressure_risk(replay_summary) do
    readiness_levels = replay_summary |> Map.get("readiness_level_counts", %{}) |> map_keys()

    import_classifications =
      replay_summary |> Map.get("import_classification_counts", %{}) |> map_keys()

    gate_statuses = replay_summary |> Map.get("gate_status_counts", %{}) |> map_keys()

    gate_classifications =
      replay_summary |> Map.get("gate_classification_counts", %{}) |> map_keys()

    [
      %{
        "type" => "quality_gate_pressure",
        "severity" =>
          readiness_pressure_risk_severity(%{
            "readiness_level" => pressure_priority_value(readiness_levels),
            "import_classification" => pressure_priority_value(import_classifications),
            "gate_status" => pressure_priority_value(gate_statuses),
            "gate_classification" => pressure_priority_value(gate_classifications)
          }),
        "reason" =>
          "candidate source quality-gate replay reports review, blocked, analysis-only, or import-boundary pressure",
        "readiness_level" => pressure_priority_value(readiness_levels),
        "import_classification" => pressure_priority_value(import_classifications),
        "quality_gate_status" => pressure_priority_value(gate_statuses),
        "gate_classification" => pressure_priority_value(gate_classifications),
        "readiness_levels" => readiness_levels,
        "import_classifications" => import_classifications,
        "quality_gate_statuses" => gate_statuses,
        "gate_classifications" => gate_classifications,
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "gate_count" => Map.get(replay_summary, "gate_count"),
        "passed_gate_count" => Map.get(replay_summary, "passed_gate_count"),
        "review_gate_count" => Map.get(replay_summary, "review_gate_count"),
        "analysis_gate_count" => Map.get(replay_summary, "analysis_gate_count"),
        "blocked_gate_count" => Map.get(replay_summary, "blocked_gate_count"),
        "non_passed_gate_count" => Map.get(replay_summary, "non_passed_gate_count"),
        "gate_status_counts" => Map.get(replay_summary, "gate_status_counts"),
        "gate_classification_counts" => Map.get(replay_summary, "gate_classification_counts"),
        "review_required_gate_ids" => Map.get(replay_summary, "review_required_gate_ids"),
        "analysis_only_gate_ids" => Map.get(replay_summary, "analysis_only_gate_ids"),
        "blocked_gate_ids" => Map.get(replay_summary, "blocked_gate_ids"),
        "non_passed_gate_ids" => Map.get(replay_summary, "non_passed_gate_ids"),
        "review_required_quality_gate_row_ids" =>
          Map.get(replay_summary, "review_required_quality_gate_row_ids"),
        "analysis_only_quality_gate_row_ids" =>
          Map.get(replay_summary, "analysis_only_quality_gate_row_ids"),
        "blocked_quality_gate_row_ids" => Map.get(replay_summary, "blocked_quality_gate_row_ids"),
        "non_passed_quality_gate_row_ids" =>
          Map.get(replay_summary, "non_passed_quality_gate_row_ids"),
        "branch_local_review_pressure" => Map.get(replay_summary, "branch_local_review_pressure"),
        "branch_local_import_pressure" => Map.get(replay_summary, "branch_local_import_pressure"),
        "feedback_source" => "candidate_source.quality_gate_replay_summary",
        "feedback_scope" => "quality_gate",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end
end
