defmodule OrbitalDynamics.OperationalReadiness.CadenceImportGate do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.TimelinePublicationContext

  def build(evidence) do
    cond do
      evidence["blocked_import_count"] > 0 or evidence["invalid_cadence_import_count"] > 0 ->
        gate(
          "blocked",
          "blocked",
          "Cadence import evidence is blocked or invalid",
          context(evidence)
        )

      evidence["schema_validation_fail_count"] > 0 or
          evidence["schema_validation_error_count"] > 0 ->
        gate(
          "blocked",
          "blocked",
          "source schema-validation evidence failed",
          context(evidence)
        )

      evidence["manifest_review_required_count"] > 0 or evidence["missing_import_count"] > 0 ->
        gate(
          "review_required",
          "review_only",
          "Cadence import evidence requires review or import preparation",
          context(evidence)
        )

      evidence["stale_freshness_count"] > 0 or evidence["unknown_freshness_count"] > 0 ->
        gate(
          "review_required",
          "review_only",
          "source freshness evidence is stale or unknown",
          context(evidence)
        )

      evidence["ready_for_import_count"] > 0 ->
        gate(
          "passed",
          "importable",
          "Cadence import manifest has ready-for-import rows",
          context(evidence)
        )

      true ->
        gate(
          "analysis_only",
          "analysis_only",
          "no ready-for-import rows were available",
          context(evidence)
        )
    end
  end

  def context(evidence) do
    %{
      "ready_for_import_count" => evidence["ready_for_import_count"],
      "manifest_review_required_count" => evidence["manifest_review_required_count"],
      "blocked_import_count" => evidence["blocked_import_count"],
      "missing_import_count" => evidence["missing_import_count"],
      "invalid_cadence_import_count" => evidence["invalid_cadence_import_count"],
      "current_freshness_count" => evidence["current_freshness_count"],
      "stale_freshness_count" => evidence["stale_freshness_count"],
      "unknown_freshness_count" => evidence["unknown_freshness_count"],
      "freshness_status_counts" => positive_count_map(evidence["freshness_status_counts"]),
      "schema_validation_pass_count" => evidence["schema_validation_pass_count"],
      "schema_validation_fail_count" => evidence["schema_validation_fail_count"],
      "schema_validation_error_count" => evidence["schema_validation_error_count"],
      "schema_validation_warning_count" => evidence["schema_validation_warning_count"],
      "schema_validation_remediation_count" => evidence["schema_validation_remediation_count"],
      "schema_validation_status_counts" =>
        positive_count_map(evidence["schema_validation_status_counts"]),
      "import_status_counts" => positive_count_map(evidence["import_status_counts"]),
      "cadence_import_status_counts" =>
        positive_count_map(evidence["cadence_import_status_counts"])
    }
    |> Map.merge(TimelinePublicationContext.from_evidence(evidence))
  end

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp positive_count_map(_counts), do: %{}

  defp gate(status, classification, reason, context) do
    %{
      "id" => "cadence_import",
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
    |> Map.merge(context)
  end
end
