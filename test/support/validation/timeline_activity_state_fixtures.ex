defmodule OrbitalDynamics.Validation.TimelineActivityStateFixtures do
  @moduledoc false

  alias OrbitalDynamics.Validation

  def timeline_activity_precondition_summary_fixture_observations do
    "timeline_activity_precondition_summary.v1"
    |> Validation.artifact_observations(timeline_activity_precondition_summary_fixture())
  end

  def timeline_activity_precondition_summary_fixture do
    read_json!("study_results/timeline_activity_precondition_summary_v1.json")
  end

  def generated_timeline_activity_precondition_summary_fixture do
    %{
      "id" => "cmd_source",
      "type" => "command",
      "scenario_id" => "leo_1",
      "metadata" => %{"timeline_id" => "timeline:cmd_source"},
      "payload_available" => false,
      "resource_blocking_dimension" => "power",
      "degraded" => true
    }
    |> OrbitalDynamics.timeline_activity_precondition_summary()
  end

  def timeline_activity_state_fixture_observations do
    "timeline_activity_state.v1"
    |> Validation.artifact_observations(timeline_activity_state_fixture())
  end

  def timeline_activity_state_fixture do
    read_json!("study_results/timeline_activity_state_v1.json")
  end

  def generated_timeline_activity_state_fixture do
    planned = %{
      id: :cmd_lock,
      type: :command,
      status: :approved,
      approved: true,
      locked: true,
      starts_at_s: 100,
      ends_at_s: 120,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    realized = %{
      id: :cmd_new,
      type: :command,
      status: :executed,
      starts_at_s: 130,
      ends_at_s: 140,
      metadata: %{timeline_id: :"timeline:cmd_new"}
    }

    OrbitalDynamics.timeline_activity_state(planned, realized)
  end

  def timeline_activity_approval_state_fixture_observations do
    "timeline_activity_approval_state.v1"
    |> Validation.artifact_observations(timeline_activity_approval_state_fixture())
  end

  def timeline_activity_approval_state_fixture do
    read_json!("study_results/timeline_activity_approval_state_v1.json")
  end

  def generated_timeline_activity_approval_state_fixture do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: "Review Required",
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      source_window_id: :"command:cmd_provider",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      approval_status: :approved,
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    OrbitalDynamics.timeline_activity_approval_state(planned, realized)
  end

  def timeline_activity_status_state_fixture_observations do
    "timeline_activity_status_state.v1"
    |> Validation.artifact_observations(timeline_activity_status_state_fixture())
  end

  def timeline_activity_status_state_fixture do
    read_json!("study_results/timeline_activity_status_state_v1.json")
  end

  def generated_timeline_activity_status_state_fixture do
    planned = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "In Progress",
      source_window_id: :"visibility:obs_provider",
      metadata: %{
        timeline_id: :"timeline:obs_provider",
        source_window_id: :"visibility:obs_provider"
      }
    }

    realized = %{
      id: :obs_provider,
      type: :observe,
      scenario_id: :leo_1,
      status: "succeeded",
      metadata: %{timeline_id: :"timeline:obs_provider"}
    }

    OrbitalDynamics.timeline_activity_status_state(planned, realized)
  end

  def timeline_activity_lifecycle_state_fixture_observations do
    "timeline_activity_lifecycle_state.v1"
    |> Validation.artifact_observations(timeline_activity_lifecycle_state_fixture())
  end

  def timeline_activity_lifecycle_state_fixture do
    read_json!("study_results/timeline_activity_lifecycle_state_v1.json")
  end

  def generated_timeline_activity_lifecycle_state_fixture do
    planned = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "In Progress",
      approval_status: "Review Required",
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      source_window_id: :"command:cmd_provider",
      metadata: %{
        timeline_id: :"timeline:cmd_provider",
        source_window_id: :"command:cmd_provider"
      }
    }

    realized = %{
      id: :cmd_provider,
      type: :command,
      scenario_id: :leo_1,
      status: "succeeded",
      approval_status: :approved,
      command_window_id: :"command_window:cmd_provider",
      command_window_type: :command_window,
      metadata: %{timeline_id: :"timeline:cmd_provider"}
    }

    OrbitalDynamics.timeline_activity_lifecycle_state(planned, realized)
  end

  def timeline_lifecycle_state_summary_fixture_observations do
    "timeline_lifecycle_state_summary.v1"
    |> Validation.artifact_observations(timeline_lifecycle_state_summary_fixture())
  end

  def timeline_lifecycle_state_summary_fixture do
    read_json!("study_results/timeline_lifecycle_state_summary_v1.json")
  end

  def generated_timeline_lifecycle_state_summary_fixture do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        scenario_id: :leo_1,
        status: "In Progress",
        approval_status: "Review Required",
        command_window_id: :"command_window:cmd_provider",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :planned,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        command_window_id: :"command_window:done_keep",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:done_keep"}
      },
      %{
        id: :dup_a,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      },
      %{
        id: :dup_b,
        type: :observe,
        status: :planned,
        metadata: %{timeline_id: :"timeline:dup"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        scenario_id: :leo_1,
        status: "succeeded",
        approval_status: :approved,
        command_window_id: :"command_window:cmd_provider",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      },
      %{
        id: :obs_record,
        type: :observe,
        status: :completed,
        approval_status: :not_required,
        metadata: %{timeline_id: :"timeline:obs_record"}
      },
      %{
        id: :done_keep,
        type: :command,
        status: :completed,
        approval_status: :approved,
        command_window_id: :"command_window:done_keep",
        command_window_type: :command_window,
        metadata: %{timeline_id: :"timeline:done_keep"}
      }
    ]

    OrbitalDynamics.timeline_lifecycle_state_summary(
      planned,
      realized,
      source: "validation.timeline_lifecycle_state_summary"
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
