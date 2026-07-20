defmodule OrbitalDynamics.OperationalReadiness.MissionPolicyGate do
  @moduledoc false

  def build(evidence) do
    cond do
      evidence["policy_blocked_count"] > 0 ->
        gate(
          "blocked",
          "blocked",
          "mission-policy evidence blocks import eligibility",
          evidence
        )

      evidence["policy_review_required_count"] > 0 ->
        gate(
          "review_required",
          "review_only",
          "mission-policy evidence requires operator review before import",
          evidence
        )

      evidence["policy_decision_count"] > 0 ->
        gate(
          "passed",
          "importable",
          "mission-policy evidence is auto-approvable",
          evidence
        )

      true ->
        nil
    end
  end

  def context(evidence) do
    %{
      "policy_decision_count" => evidence["policy_decision_count"],
      "policy_classification_counts" => evidence["policy_classification_counts"]
    }
  end

  defp gate(status, classification, reason, evidence) do
    %{
      "id" => "mission_policy",
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
    |> Map.merge(context(evidence))
  end
end
