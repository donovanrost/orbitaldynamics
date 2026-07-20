defmodule OrbitalDynamics.Schema.StateRefreshArtifactValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_equal: 5, require_fields: 4]

  alias OrbitalDynamics.Schema.{
    CandidateRejectionValidation,
    ContactAllocationValidation
  }

  def validate(issues, path, artifact, "accepted_planning_state.v1" = name),
    do:
      OrbitalDynamics.Schema.AcceptedStateContracts.validate_planning_state(
        issues,
        path,
        artifact,
        required_fields(name)
      )

  def validate(issues, _path, artifact, "candidate_refresh.v1" = name),
    do:
      OrbitalDynamics.Schema.CandidateRefreshContracts.validate(
        issues,
        artifact,
        required_fields(name),
        &ContactAllocationValidation.validate_optional_report/2,
        &CandidateRejectionValidation.validate_optional_report/3
      )

  def validate(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_artifact(path, artifact, contract_name)
  end

  defp validate_artifact(issues, path, artifact, "spacecraft_state_estimate.v1"),
    do:
      OrbitalDynamics.Schema.AcceptedStateContracts.validate_spacecraft_state_estimate(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "maneuver_execution_delta.v1"),
    do:
      OrbitalDynamics.Schema.AcceptedStateContracts.validate_maneuver_execution_delta(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "candidate_activity.v1"),
    do: OrbitalDynamics.Schema.CandidateActivityContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "candidate_diff_row.v1"),
    do:
      issues
      |> expect_equal(path, artifact, "schema_contract", "candidate_diff_row.v1")
      |> OrbitalDynamics.Schema.CandidateDiffContracts.validate_row(path, artifact)

  defp validate_artifact(issues, path, artifact, "freshness_report.v1"),
    do: OrbitalDynamics.Schema.FreshnessReportContracts.validate_optional(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "invalidated_candidate.v1"),
    do:
      issues
      |> expect_equal(path, artifact, "schema_contract", "invalidated_candidate.v1")
      |> OrbitalDynamics.Schema.CandidateDiffContracts.validate_invalidated_candidate(
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "refresh_budget_report.v1"),
    do: OrbitalDynamics.Schema.RefreshBudgetReportContracts.validate(issues, path, artifact)

  defp validate_artifact(issues, path, artifact, "refreshed_window.v1"),
    do:
      issues
      |> expect_equal(path, artifact, "schema_contract", "refreshed_window.v1")
      |> OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_refreshed_window(
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "remaining_horizon.v1"),
    do:
      OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_remaining_horizon(
        issues,
        path,
        artifact
      )

  defp validate_artifact(issues, path, artifact, "source_window_lineage.v1"),
    do:
      issues
      |> expect_equal(path, artifact, "schema_contract", "source_window_lineage.v1")
      |> OrbitalDynamics.Schema.CandidateDiffContracts.validate_source_window_lineage(
        path,
        artifact
      )

  defp required_fields(contract_name) do
    [
      OrbitalDynamics.Schema.AcceptedStateRegistryContracts,
      OrbitalDynamics.Schema.CandidateRefreshRegistryContracts
    ]
    |> Enum.reduce(%{}, &Map.merge(&2, &1.contracts()))
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end
end
