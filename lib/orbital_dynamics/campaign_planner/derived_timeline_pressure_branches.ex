defmodule OrbitalDynamics.CampaignPlanner.DerivedTimelinePressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    TimelineDiffPressureEventCallbacks,
    TimelineDiffPressureEvents,
    TimelinePressureBranches,
    TimelineSourceReports
  }

  def build(prior_plan, mission_state, policy) do
    []
    |> Kernel.++(prior_timeline_integrity(prior_plan))
    |> Kernel.++(mission_timeline_integrity(mission_state))
    |> Kernel.++(prior_timeline_dependency_impact(prior_plan))
    |> Kernel.++(mission_timeline_dependency_impact(mission_state))
    |> Kernel.++(prior_timeline_publication(prior_plan))
    |> Kernel.++(mission_timeline_publication(mission_state))
    |> Kernel.++(prior_timeline_lifecycle_state(prior_plan))
    |> Kernel.++(mission_timeline_lifecycle_state(mission_state))
    |> Kernel.++(prior_timeline_activity_lifecycle_state(prior_plan))
    |> Kernel.++(mission_timeline_activity_lifecycle_state(mission_state))
    |> Kernel.++(prior_timeline_activity_precondition(prior_plan))
    |> Kernel.++(mission_timeline_activity_precondition(mission_state))
    |> Kernel.++(prior_timeline_preservation(prior_plan))
    |> Kernel.++(mission_timeline_preservation(mission_state))
    |> Kernel.++(prior_timeline_diff(prior_plan, policy))
    |> Kernel.++(mission_timeline_diff(mission_state, policy))
  end

  defp prior_timeline_diff(prior_plan, policy) do
    TimelineSourceReports.timeline_diff_pressure_rows(
      TimelineSourceReports.prior_plan_timeline_diff_reports(prior_plan),
      TimelineSourceReports.prior_plan_timeline_transition_application_reports(prior_plan)
    )
    |> Enum.flat_map(fn {row, source_path, index} ->
      timeline_diff_pressure_branch(row, source_path, index, policy)
    end)
  end

  defp prior_timeline_integrity(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_integrity_reports()
    |> TimelineSourceReports.timeline_integrity_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_integrity_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp prior_timeline_dependency_impact(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_dependency_impact_summaries()
    |> TimelineSourceReports.timeline_dependency_impact_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_dependency_impact_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp prior_timeline_publication(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_publication_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_publication_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp prior_timeline_lifecycle_state(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_lifecycle_state_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_lifecycle_state_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp prior_timeline_activity_lifecycle_state(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_activity_lifecycle_states()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {state, source_path, index} ->
      TimelinePressureBranches.timeline_activity_lifecycle_state_pressure_branch(
        state,
        source_path,
        index
      )
    end)
  end

  defp prior_timeline_activity_precondition(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_activity_precondition_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_activity_precondition_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp prior_timeline_preservation(prior_plan) do
    report_rows =
      prior_plan
      |> TimelineSourceReports.prior_plan_timeline_preservation_reports()
      |> TimelineSourceReports.timeline_preservation_report_pressure_rows()

    status_rows =
      prior_plan
      |> TimelineSourceReports.prior_plan_timeline_preservation_statuses()
      |> TimelineSourceReports.timeline_preservation_status_pressure_rows()

    (report_rows ++ status_rows)
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_preservation_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_diff(mission_state, policy) do
    TimelineSourceReports.timeline_diff_pressure_rows(
      TimelineSourceReports.mission_state_timeline_diff_reports(mission_state),
      TimelineSourceReports.mission_state_timeline_transition_application_reports(mission_state)
    )
    |> Enum.flat_map(fn {row, source_path, index} ->
      timeline_diff_pressure_branch(row, source_path, index, policy)
    end)
  end

  defp mission_timeline_integrity(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_integrity_reports()
    |> TimelineSourceReports.timeline_integrity_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_integrity_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_dependency_impact(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_dependency_impact_summaries()
    |> TimelineSourceReports.timeline_dependency_impact_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_dependency_impact_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_publication(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_publication_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_publication_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_lifecycle_state(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_lifecycle_state_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_lifecycle_state_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_activity_lifecycle_state(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_activity_lifecycle_states()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {state, source_path, index} ->
      TimelinePressureBranches.timeline_activity_lifecycle_state_pressure_branch(
        state,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_activity_precondition(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_activity_precondition_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_activity_precondition_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp mission_timeline_preservation(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_preservation_reports()
    |> TimelineSourceReports.timeline_preservation_report_pressure_rows()
    |> Kernel.++(
      mission_state
      |> TimelineSourceReports.mission_state_timeline_preservation_statuses()
      |> TimelineSourceReports.timeline_preservation_status_pressure_rows()
    )
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_preservation_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp timeline_diff_pressure_branch(row, source_path, index, policy) do
    TimelineDiffPressureEvents.pressure_branch(
      row,
      source_path,
      index,
      policy,
      TimelineDiffPressureEventCallbacks.callbacks()
    )
  end
end
