defmodule OrbitalDynamics.Validation.OperationalPlanningFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def command_window_report_fixture_observations do
    "command_window_report.v1"
    |> Validation.artifact_observations(command_window_report_fixture())
  end

  def command_window_report_fixture do
    read_json!("study_results/command_window_report_v1.json")
  end

  def constraint_report_fixture_observations do
    "constraint_report.v1"
    |> Validation.artifact_observations(constraint_report_fixture())
  end

  def constraint_report_fixture do
    read_json!("study_results/constraint_report_v1.json")
  end

  def operational_timeline_report_fixture_observations do
    "operational_timeline_report.v1"
    |> Validation.artifact_observations(operational_timeline_report_fixture())
  end

  def operational_timeline_report_fixture do
    read_json!("study_results/operational_timeline_report_v1.json")
  end

  def generated_operational_timeline_report_fixture do
    [
      %{
        id: :health_1,
        type: :health_check,
        scenario_id: :leo_1,
        starts_at_s: 20.0,
        ends_at_s: 35.0,
        approval_status: :approved,
        source_window_id: :health_window_1
      },
      %{
        id: :cmd_1,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        dependencies: [:health_1, :ops_gate],
        exclusive_with_activity_ids: [:dl_1],
        exclusivity_group: :station_dss_14_ops,
        approval_status: :pending,
        cadence_import: %{activity_type: :command_window},
        direction: :command,
        source_window_id: :cmd_window_1
      },
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :dss_14,
        starts_at_s: 35.0,
        ends_at_s: 60.0,
        approval_status: :approved,
        direction: :downlink,
        exclusivity_group: :station_dss_14_ops
      }
    ]
    |> OrbitalDynamics.operational_timeline_report(
      source: "mission_plan.activities",
      validate_missing_dependencies?: true
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
