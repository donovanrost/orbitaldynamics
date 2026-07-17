defmodule OrbitalDynamics.Validation.ResourceSafetyFixtures do
  @moduledoc false

  alias OrbitalDynamics.{ResourceFilter, ResourceProjection, Validation}

  def resource_projection_battery_handoff_fixture_observations do
    "resource_projection_report.v1"
    |> Validation.artifact_observations(resource_projection_battery_handoff_fixture())
  end

  def resource_projection_battery_handoff_fixture do
    read_json!("study_results/resource_projection_battery_handoff_v1.json")
  end

  def operator_review_resource_projection_battery_handoff_fixture_observations do
    "study_results/operator_review_resource_projection_battery_handoff_v1.json"
    |> read_json!()
    |> then(&Validation.artifact_observations("operator_review_package.v1", &1))
  end

  def operator_review_resource_projection_battery_handoff_fixture do
    read_json!("study_results/operator_review_resource_projection_battery_handoff_v1.json")
  end

  def cadence_import_resource_projection_battery_handoff_fixture_observations do
    "cadence_import_manifest.v1"
    |> Validation.artifact_observations(
      cadence_import_resource_projection_battery_handoff_fixture()
    )
  end

  def cadence_import_resource_projection_battery_handoff_fixture do
    read_json!("study_results/cadence_import_resource_projection_battery_handoff_v1.json")
  end

  def resource_projection_stale_margin_fixture_observations do
    "resource_projection_report.v1"
    |> Validation.artifact_observations(resource_projection_stale_margin_fixture())
  end

  def resource_projection_stale_margin_fixture do
    ResourceProjection.report(
      [
        %{
          id: :obs_1,
          type: :observe,
          scenario_id: :leo_1,
          starts_at_s: 10.0,
          estimated_storage_mb: 20.0
        }
      ],
      [
        %{
          spacecraft_id: :leo_1,
          storage_capacity_mb: 100.0,
          storage_used_mb: 10.0,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 20.0
        },
        %{
          spacecraft_id: :leo_2,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 20.0,
          battery_state_of_charge: 0.7
        },
        %{
          spacecraft_id: :leo_3,
          storage_capacity_mb: 100.0,
          storage_used_mb: 10.0,
          storage_margin: 0.75
        }
      ],
      model: "thin_stale_derived_margin_resource_projection_fixture",
      source: "generated_resource_projection_stale_derived_margin_fixture",
      approval_policy: %{policy_bundle_id: "resource_projection_authority_v1"}
    )
  end

  def resource_filter_stale_margin_fixture_observations do
    "resource_filter_report.v1"
    |> Validation.artifact_observations(resource_filter_stale_margin_fixture())
  end

  def resource_filter_stale_margin_fixture do
    ResourceFilter.report(
      [
        %{
          id: :obs_1,
          type: :observe,
          scenario_id: :leo_1,
          spacecraft_id: :sat_1,
          target_id: :target_alpha,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        }
      ],
      [
        %{
          spacecraft_id: :sat_1,
          battery_capacity_wh: 100.0,
          battery_energy_used_wh: 20.0,
          battery_state_of_charge: 0.7
        },
        %{
          spacecraft_id: :sat_2,
          storage_capacity_mb: 100.0,
          storage_used_mb: 10.0,
          storage_margin: 0.75
        }
      ],
      approval_policy: %{policy_bundle_id: "degraded_payload_guard_v1"}
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
