defmodule OrbitalDynamics.Validation.TimelinePreservationFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def timeline_preservation_report_fixture_observations do
    "timeline_preservation_report.v1"
    |> Validation.artifact_observations(timeline_preservation_report_fixture())
  end

  def timeline_preservation_report_fixture do
    read_json!("study_results/timeline_preservation_report_v1.json")
  end

  def timeline_preservation_status_fixture_observations do
    "timeline_preservation_status.v1"
    |> Validation.artifact_observations(timeline_preservation_status_fixture())
  end

  def timeline_preservation_status_fixture do
    read_json!("study_results/timeline_preservation_status_v1.json")
  end

  def timeline_integrity_report_fixture_observations do
    "timeline_integrity_report.v1"
    |> Validation.artifact_observations(timeline_integrity_report_fixture())
  end

  def timeline_integrity_report_fixture do
    read_json!("study_results/timeline_integrity_report_v1.json")
  end

  def generated_timeline_integrity_report_fixture do
    [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 15.0,
        ground_station_id: :dss_14,
        direction: :command
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        direction: :command,
        dependencies: [:health_gate, :missing_gate],
        exclusive_with: [:dl_conflict]
      },
      %{
        id: :dl_conflict,
        type: :downlink,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        ground_station_id: :dss_14,
        direction: :downlink
      }
    ]
    |> OrbitalDynamics.timeline_integrity_report()
  end

  def timeline_dependency_impact_summary_fixture_observations do
    "timeline_dependency_impact_summary.v1"
    |> Validation.artifact_observations(timeline_dependency_impact_summary_fixture())
  end

  def timeline_dependency_impact_summary_fixture do
    read_json!("study_results/timeline_dependency_impact_summary_v1.json")
  end

  def timeline_diff_summary_fixture_observations do
    "timeline_diff_summary.v1"
    |> Validation.artifact_observations(timeline_diff_summary_fixture())
  end

  def timeline_diff_summary_fixture do
    read_json!("study_results/timeline_diff_summary_v1.json")
  end

  def timeline_publication_summary_fixture_observations do
    "timeline_publication_summary.v1"
    |> Validation.artifact_observations(timeline_publication_summary_fixture())
  end

  def timeline_publication_summary_fixture do
    read_json!("study_results/timeline_publication_summary_v1.json")
  end

  def generated_timeline_publication_summary_fixture do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    source_artifact = %{
      "schema_contract" => "operational_timeline_report.v1",
      "id" => "timeline:published_plan:v2"
    }

    OrbitalDynamics.timeline_publication_summary(source_artifact,
      publication_sequence: 7,
      publication_authority: :mission_operations,
      supersedes_artifact_ids: ["timeline:published_plan:v1"],
      downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
      dependency_impact_summary:
        OrbitalDynamics.timeline_dependency_impact_summary(source, replacement),
      timeline_diff_summary: OrbitalDynamics.timeline_diff_summary(source, replacement)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
