defmodule OrbitalDynamics.Validation.QualityGateFixtures do
  alias OrbitalDynamics.{OperationalReadiness, Validation}

  import OrbitalDynamics.Validation.OperationalReadinessFixtures,
    only: [operational_readiness_report_fixture: 0]

  def operational_quality_gate_summary_fixture_observations do
    "operational_quality_gate_summary.v1"
    |> Validation.artifact_observations(operational_quality_gate_summary_fixture())
  end

  def operational_quality_gate_summary_fixture do
    read_json!("study_results/operational_quality_gate_summary_v1.json")
  end

  def operational_quality_gate_import_readiness_summary_fixture_observations do
    "operational_quality_gate_import_readiness_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_import_readiness_summary_fixture()
    )
  end

  def operational_quality_gate_import_readiness_summary_fixture do
    read_json!("study_results/operational_quality_gate_import_readiness_summary_v1.json")
  end

  def operational_quality_gate_unavailable_resource_summary_fixture_observations do
    "operational_quality_gate_unavailable_resource_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_unavailable_resource_summary_fixture()
    )
  end

  def operational_quality_gate_unavailable_resource_summary_fixture do
    review_source = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "package_id" => "validation_unavailable_resource_fixture",
      "rows" => [
        %{
          "id" => "operator_review:contact_allocation:dl_resource_blocked",
          "review_type" => "contact_allocation_review",
          "approval_status" => "operator_review_required",
          "source_contact_allocation" => %{
            "contact_id" => "dl_resource_blocked",
            "type" => "downlink",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 620.0,
            "ends_at_s" => 680.0,
            "allocation_status" => "blocked",
            "allocation_reason" => "antenna_unavailable",
            "source_resource_suppression" => %{
              "id" => "dl_resource_blocked",
              "type" => "downlink",
              "spacecraft_id" => "leo_1",
              "suppressed_reason" => "antenna_unavailable",
              "resource_blocking_dimension" => "antenna",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
            }
          }
        }
      ]
    }

    review_source
    |> OperationalReadiness.report()
    |> OperationalReadiness.quality_gate_report()
    |> OrbitalDynamics.operational_quality_gate_unavailable_resource_summary()
  end

  def operational_quality_gate_unavailable_resource_summary_checked_in_observations do
    "operational_quality_gate_unavailable_resource_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_unavailable_resource_summary_checked_in_fixture()
    )
  end

  def operational_quality_gate_unavailable_resource_summary_checked_in_fixture do
    read_json!("study_results/operational_quality_gate_unavailable_resource_summary_v1.json")
  end

  def operational_quality_gate_operator_training_summary_fixture_observations do
    "operational_quality_gate_operator_training_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_operator_training_summary_fixture()
    )
  end

  def operational_quality_gate_operator_training_summary_fixture do
    read_json!("study_results/operational_quality_gate_operator_training_summary_v1.json")
  end

  def operational_quality_gate_schema_validation_summary_fixture_observations do
    "operational_quality_gate_schema_validation_summary.v1"
    |> Validation.artifact_observations(
      operational_quality_gate_schema_validation_summary_fixture()
    )
  end

  def operational_quality_gate_schema_validation_summary_fixture do
    read_json!("study_results/operational_quality_gate_schema_validation_summary_v1.json")
  end

  def quality_gate_report_fixture_observations do
    "quality_gate_report.v1"
    |> Validation.artifact_observations(quality_gate_report_fixture())
  end

  def quality_gate_report_fixture do
    operational_readiness_report_fixture()
    |> OperationalReadiness.quality_gate_report()
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
