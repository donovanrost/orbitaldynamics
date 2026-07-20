defmodule OrbitalDynamics.OperationalReadiness.OperatorReviewGate do
  @moduledoc false

  def build(evidence) do
    cond do
      evidence["blocked_review_count"] > 0 ->
        gate(
          "blocked",
          "blocked",
          "operator-review evidence includes blocked approval status"
        )

      evidence["review_required_count"] > 0 ->
        gate(
          "review_required",
          "review_only",
          "operator-review evidence requires human review before import"
        )

      evidence["review_row_count"] > 0 ->
        gate(
          "passed",
          "importable",
          "operator-review rows have no blocked or review-required status"
        )

      evidence["import_row_count"] > 0 ->
        gate(
          "passed",
          "importable",
          "Cadence import rows carry source review handoff evidence"
        )

      true ->
        gate(
          "analysis_only",
          "analysis_only",
          "no operator-review rows were available"
        )
    end
  end

  defp gate(status, classification, reason) do
    %{
      "id" => "operator_review",
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
  end
end
