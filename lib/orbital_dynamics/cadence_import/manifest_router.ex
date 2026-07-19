defmodule OrbitalDynamics.CadenceImport.ManifestRouter do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization

  def route(artifact, opts, _dispatch, _unsupported)

  def route(
        %{"schema_contract" => "cadence_import_manifest.v1"} = manifest,
        _opts,
        _dispatch,
        _unsupported
      ),
      do: manifest

  def route(
        %{schema_contract: "cadence_import_manifest.v1"} = manifest,
        _opts,
        _dispatch,
        _unsupported
      ),
      do: JsonNormalization.stringify_keys(manifest)

  def route(%{"campaign_plan" => %{} = artifact}, opts, dispatch, _unsupported),
    do: dispatch.(:from_campaign_artifact, artifact, opts)

  def route(%{campaign_plan: %{} = artifact}, opts, dispatch, _unsupported),
    do:
      artifact
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_campaign_artifact, &1, opts))

  def route(%{"candidate_refresh" => %{} = artifact}, opts, dispatch, _unsupported),
    do: dispatch.(:from_candidate_refresh_artifact, artifact, opts)

  def route(%{candidate_refresh: %{} = artifact}, opts, dispatch, _unsupported),
    do:
      artifact
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_candidate_refresh_artifact, &1, opts))

  def route(
        %{"schema_contract" => "timeline_diff_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_diff_summary, summary, opts)

  def route(
        %{schema_contract: "timeline_diff_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_diff_summary, &1, opts))

  def route(
        %{"model" => "artifact_only_timeline_diff_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_diff_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_diff_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_diff_summary, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_dependency_impact_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_dependency_impact_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_dependency_impact_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_dependency_impact_summary, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_publication_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_publication_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_publication_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_publication_summary, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_activity_precondition_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_activity_precondition_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_activity_precondition_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_activity_precondition_summary, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_lifecycle_state_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_lifecycle_state_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_lifecycle_state_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_lifecycle_state_summary, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_activity_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, "schema_contract") do
    dispatch.(:from_timeline_activity_state, state, opts)
  end

  def route(
        %{model: "artifact_only_timeline_activity_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, :schema_contract) do
    state
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_activity_state, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_activity_status_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, "schema_contract") do
    dispatch.(:from_timeline_activity_status_state, state, opts)
  end

  def route(
        %{model: "artifact_only_timeline_activity_status_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, :schema_contract) do
    state
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_activity_status_state, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_activity_approval_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, "schema_contract") do
    dispatch.(:from_timeline_activity_approval_state, state, opts)
  end

  def route(
        %{model: "artifact_only_timeline_activity_approval_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, :schema_contract) do
    state
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_activity_approval_state, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_activity_lifecycle_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, "schema_contract") do
    dispatch.(:from_timeline_activity_lifecycle_state, state, opts)
  end

  def route(
        %{model: "artifact_only_timeline_activity_lifecycle_state"} = state,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(state, :schema_contract) do
    state
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_activity_lifecycle_state, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_lifecycle_preservation_summary"} = report,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(report, "schema_contract") do
    dispatch.(:from_timeline_preservation_report, report, opts)
  end

  def route(
        %{model: "artifact_only_lifecycle_preservation_summary"} = report,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(report, :schema_contract) do
    report
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_preservation_report, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_lifecycle_preservation_status"} = status,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(status, "schema_contract") do
    dispatch.(:from_timeline_preservation_status, status, opts)
  end

  def route(
        %{model: "artifact_only_lifecycle_preservation_status"} = status,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(status, :schema_contract) do
    status
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_preservation_status, &1, opts))
  end

  def route(
        %{"schema_contract" => "timeline_integrity_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_integrity_report, report, opts)

  def route(
        %{schema_contract: "timeline_integrity_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_integrity_report, &1, opts))

  def route(
        %{"model" => "artifact_only_timeline_integrity_summary"} = report,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(report, "schema_contract") do
    dispatch.(:from_timeline_integrity_report, report, opts)
  end

  def route(
        %{model: "artifact_only_timeline_integrity_summary"} = report,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(report, :schema_contract) do
    report
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_integrity_report, &1, opts))
  end

  def route(
        %{"schema_contract" => "timeline_transition_application_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_transition_application_summary, summary, opts)

  def route(
        %{schema_contract: "timeline_transition_application_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_transition_application_summary, &1, opts))

  def route(
        %{"model" => "artifact_only_timeline_transition_application_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_transition_application_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_transition_application_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_transition_application_summary, &1, opts))
  end

  def route(%{"schema_version" => 2} = artifact, opts, dispatch, _unsupported)
      when not is_map_key(artifact, "schema_contract") do
    dispatch.(:from_repair_artifact, artifact, opts)
  end

  def route(
        %{"schema_version" => 1, "run" => %{}, "execution_report" => %{}} = artifact,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(artifact, "schema_contract") do
    dispatch.(:from_result_artifact, artifact, opts)
  end

  def route(%{"schema_version" => 3} = artifact, opts, dispatch, _unsupported)
      when not is_map_key(artifact, "schema_contract") do
    dispatch.(:from_strategy_artifact, artifact, opts)
  end

  def route(%{"schema_version" => 1} = artifact, opts, dispatch, _unsupported)
      when not is_map_key(artifact, "schema_contract") do
    dispatch.(:from_campaign_artifact, artifact, opts)
  end

  def route(
        %{"schema_contract" => "campaign_repair.v2"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_repair_artifact, artifact, opts)

  def route(
        %{"schema_contract" => "campaign_strategy.v3"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_strategy_artifact, artifact, opts)

  def route(
        %{"schema_contract" => "campaign_plan.v1"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_campaign_artifact, artifact, opts)

  def route(
        %{"schema_contract" => "candidate_refresh.v1"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_candidate_refresh_artifact, artifact, opts)

  def route(
        %{"schema_contract" => "result_artifact.v1"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_result_artifact, artifact, opts)

  def route(%{schema_version: 2} = artifact, opts, dispatch, _unsupported)
      when not is_map_key(artifact, :schema_contract) do
    artifact
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_repair_artifact, &1, opts))
  end

  def route(
        %{schema_version: 1, run: %{}, execution_report: %{}} = artifact,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(artifact, :schema_contract) do
    artifact
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_result_artifact, &1, opts))
  end

  def route(%{schema_version: 3} = artifact, opts, dispatch, _unsupported)
      when not is_map_key(artifact, :schema_contract) do
    artifact
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_strategy_artifact, &1, opts))
  end

  def route(%{schema_version: 1} = artifact, opts, dispatch, _unsupported)
      when not is_map_key(artifact, :schema_contract) do
    artifact
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_campaign_artifact, &1, opts))
  end

  def route(%{schema_contract: "campaign_repair.v2"} = artifact, opts, dispatch, _unsupported),
    do:
      artifact
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_repair_artifact, &1, opts))

  def route(
        %{schema_contract: "campaign_strategy.v3"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        artifact
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_strategy_artifact, &1, opts))

  def route(%{schema_contract: "campaign_plan.v1"} = artifact, opts, dispatch, _unsupported),
    do:
      artifact
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_campaign_artifact, &1, opts))

  def route(
        %{schema_contract: "candidate_refresh.v1"} = artifact,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        artifact
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_candidate_refresh_artifact, &1, opts))

  def route(%{schema_contract: "result_artifact.v1"} = artifact, opts, dispatch, _unsupported),
    do:
      artifact
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_result_artifact, &1, opts))

  def route(
        %{"cadence_import" => %{"schema_contract" => "proposed_contact.v1"}} = contact,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(contact, "schema_contract"),
      do: dispatch.(:from_proposed_contact, contact, opts)

  def route(
        %{cadence_import: %{schema_contract: "proposed_contact.v1"}} = contact,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(contact, :schema_contract),
      do:
        contact
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_proposed_contact, &1, opts))

  def route(
        %{"schema_contract" => "proposed_contact.v1"} = contact,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_proposed_contact, contact, opts)

  def route(%{schema_contract: "proposed_contact.v1"} = contact, opts, dispatch, _unsupported),
    do:
      contact
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_proposed_contact, &1, opts))

  def route(
        %{"schema_contract" => "planned_activity.v1"} = activity,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_planned_activity, activity, opts)

  def route(%{schema_contract: "planned_activity.v1"} = activity, opts, dispatch, _unsupported),
    do:
      activity
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_planned_activity, &1, opts))

  def route(
        %{"schema_contract" => "realized_activity.v1"} = activity,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_realized_activity, activity, opts)

  def route(
        %{schema_contract: "realized_activity.v1"} = activity,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        activity
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_realized_activity, &1, opts))

  def route(
        %{"schema_contract" => "realized_state_snapshot.v1"} = snapshot,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_realized_state_snapshot, snapshot, opts)

  def route(
        %{schema_contract: "realized_state_snapshot.v1"} = snapshot,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        snapshot
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_realized_state_snapshot, &1, opts))

  def route(
        %{"schema_contract" => "operator_review_package.v1"} = package,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_operator_review_package, package, opts)

  def route(
        %{schema_contract: "operator_review_package.v1"} = package,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        package
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_operator_review_package, &1, opts))

  def route(
        %{"schema_contract" => "timeline_feedback_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_feedback_report, report, opts)

  def route(
        %{schema_contract: "timeline_feedback_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_feedback_report, &1, opts))

  def route(
        %{"schema_contract" => "operational_timeline_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_operational_timeline_report, report, opts)

  def route(
        %{schema_contract: "operational_timeline_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_operational_timeline_report, &1, opts))

  def route(
        %{"schema_contract" => "contact_contention_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_contact_contention_report, report, opts)

  def route(
        %{schema_contract: "contact_contention_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_contact_contention_report, &1, opts))

  def route(
        %{"schema_contract" => "contact_contention_resolution_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_contact_contention_resolution_report, report, opts)

  def route(
        %{schema_contract: "contact_contention_resolution_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_contact_contention_resolution_report, &1, opts))

  def route(
        %{"schema_contract" => "command_window_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_command_window_report, report, opts)

  def route(
        %{schema_contract: "command_window_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_command_window_report, &1, opts))

  def route(
        %{"schema_contract" => "station_calendar_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_station_calendar_report, report, opts)

  def route(
        %{schema_contract: "station_calendar_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_station_calendar_report, &1, opts))

  def route(
        %{"schema_contract" => "station_reservation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_station_reservation_report, report, opts)

  def route(
        %{schema_contract: "station_reservation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_station_reservation_report, &1, opts))

  def route(
        %{"schema_contract" => "link_capacity_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_link_capacity_report, report, opts)

  def route(
        %{schema_contract: "link_capacity_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_link_capacity_report, &1, opts))

  def route(
        %{"schema_contract" => "contact_allocation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_contact_allocation_report, report, opts)

  def route(
        %{schema_contract: "contact_allocation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_contact_allocation_report, &1, opts))

  def route(
        %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_contact_allocation_capacity_pack_summary, summary, opts)

  def route(
        %{schema_contract: "contact_allocation_capacity_pack_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_contact_allocation_capacity_pack_summary, &1, opts))

  def route(
        %{"schema_contract" => "contact_allocation_reservation_conflict_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_contact_allocation_reservation_conflict_summary, summary, opts)

  def route(
        %{schema_contract: "contact_allocation_reservation_conflict_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_contact_allocation_reservation_conflict_summary, &1, opts))

  def route(%{"schema_contract" => "contact_intent.v1"} = intent, opts, dispatch, _unsupported),
    do: dispatch.(:from_contact_intent, intent, opts)

  def route(%{schema_contract: "contact_intent.v1"} = intent, opts, dispatch, _unsupported),
    do:
      intent
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_contact_intent, &1, opts))

  def route(
        %{"schema_contract" => "resource_projection_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_resource_projection_report, report, opts)

  def route(
        %{schema_contract: "resource_projection_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_resource_projection_report, &1, opts))

  def route(
        %{"schema_contract" => "resource_projection_flow_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_resource_projection_flow_summary, summary, opts)

  def route(
        %{schema_contract: "resource_projection_flow_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_resource_projection_flow_summary, &1, opts))

  def route(
        %{"schema_contract" => "contact_filter_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_contact_filter_report, report, opts)

  def route(
        %{schema_contract: "contact_filter_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_contact_filter_report, &1, opts))

  def route(
        %{"schema_contract" => "candidate_diff_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_candidate_diff_report, report, opts)

  def route(
        %{schema_contract: "candidate_diff_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_candidate_diff_report, &1, opts))

  def route(
        %{"schema_contract" => "candidate_rejection_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_candidate_rejection_report, report, opts)

  def route(
        %{schema_contract: "candidate_rejection_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_candidate_rejection_report, &1, opts))

  def route(
        %{"schema_contract" => "provider_counteroffer_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_provider_counteroffer_report, report, opts)

  def route(
        %{schema_contract: "provider_counteroffer_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_provider_counteroffer_report, &1, opts))

  def route(
        %{"schema_contract" => "invalidated_candidate.v1"} = candidate,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_invalidated_candidate, candidate, opts)

  def route(
        %{schema_contract: "invalidated_candidate.v1"} = candidate,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        candidate
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_invalidated_candidate, &1, opts))

  def route(
        %{"schema_contract" => "resource_filter_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_resource_filter_report, report, opts)

  def route(
        %{schema_contract: "resource_filter_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_resource_filter_report, &1, opts))

  def route(
        %{"schema_contract" => "freshness_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_freshness_report, report, opts)

  def route(%{schema_contract: "freshness_report.v1"} = report, opts, dispatch, _unsupported),
    do:
      report
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_freshness_report, &1, opts))

  def route(
        %{"schema_contract" => "refresh_budget_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_refresh_budget_report, report, opts)

  def route(
        %{schema_contract: "refresh_budget_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_refresh_budget_report, &1, opts))

  def route(
        %{"schema_contract" => "constraint_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_constraint_report, report, opts)

  def route(%{schema_contract: "constraint_report.v1"} = report, opts, dispatch, _unsupported),
    do:
      report
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_constraint_report, &1, opts))

  def route(
        %{"schema_contract" => "objective_satisfaction_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_objective_satisfaction_report, report, opts)

  def route(
        %{schema_contract: "objective_satisfaction_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_objective_satisfaction_report, &1, opts))

  def route(
        %{"schema_contract" => "maneuver_recommendation.v1"} = recommendation,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_maneuver_recommendation, recommendation, opts)

  def route(
        %{schema_contract: "maneuver_recommendation.v1"} = recommendation,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        recommendation
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_maneuver_recommendation, &1, opts))

  def route(
        %{"schema_contract" => "maneuver_execution_delta.v1"} = delta,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_maneuver_execution_delta, delta, opts)

  def route(
        %{schema_contract: "maneuver_execution_delta.v1"} = delta,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        delta
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_maneuver_execution_delta, &1, opts))

  def route(
        %{"schema_contract" => "maneuver_review_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_maneuver_review_report, report, opts)

  def route(
        %{schema_contract: "maneuver_review_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_maneuver_review_report, &1, opts))

  def route(
        %{"schema_contract" => "timeline_diff_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_diff_report, report, opts)

  def route(
        %{schema_contract: "timeline_diff_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_diff_report, &1, opts))

  def route(
        %{"schema_contract" => "timeline_dependency_impact_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_dependency_impact_summary, summary, opts)

  def route(
        %{schema_contract: "timeline_dependency_impact_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_dependency_impact_summary, &1, opts))

  def route(
        %{"schema_contract" => "timeline_publication_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_publication_summary, summary, opts)

  def route(
        %{schema_contract: "timeline_publication_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_publication_summary, &1, opts))

  def route(
        %{"schema_contract" => "timeline_activity_precondition_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_activity_precondition_summary, summary, opts)

  def route(
        %{schema_contract: "timeline_activity_precondition_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_activity_precondition_summary, &1, opts))

  def route(
        %{"schema_contract" => "timeline_lifecycle_state_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_lifecycle_state_summary, summary, opts)

  def route(
        %{schema_contract: "timeline_lifecycle_state_summary.v1"} = summary,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        summary
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_lifecycle_state_summary, &1, opts))

  def route(
        %{"schema_contract" => "timeline_activity_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_activity_state, state, opts)

  def route(
        %{schema_contract: "timeline_activity_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        state
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_activity_state, &1, opts))

  def route(
        %{"schema_contract" => "timeline_activity_status_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_activity_status_state, state, opts)

  def route(
        %{schema_contract: "timeline_activity_status_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        state
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_activity_status_state, &1, opts))

  def route(
        %{"schema_contract" => "timeline_activity_approval_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_activity_approval_state, state, opts)

  def route(
        %{schema_contract: "timeline_activity_approval_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        state
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_activity_approval_state, &1, opts))

  def route(
        %{"schema_contract" => "timeline_activity_lifecycle_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_activity_lifecycle_state, state, opts)

  def route(
        %{schema_contract: "timeline_activity_lifecycle_state.v1"} = state,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        state
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_activity_lifecycle_state, &1, opts))

  def route(
        %{"schema_contract" => "timeline_preservation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_preservation_report, report, opts)

  def route(
        %{schema_contract: "timeline_preservation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_preservation_report, &1, opts))

  def route(
        %{"schema_contract" => "timeline_preservation_status.v1"} = status,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_preservation_status, status, opts)

  def route(
        %{schema_contract: "timeline_preservation_status.v1"} = status,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        status
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_preservation_status, &1, opts))

  def route(
        %{"model" => "artifact_only_timeline_diff_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_diff_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_diff_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_diff_summary, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_integrity_summary"} = report,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(report, "schema_contract") do
    dispatch.(:from_timeline_integrity_report, report, opts)
  end

  def route(
        %{model: "artifact_only_timeline_integrity_summary"} = report,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(report, :schema_contract) do
    report
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_integrity_report, &1, opts))
  end

  def route(
        %{"model" => "artifact_only_timeline_transition_application_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, "schema_contract") do
    dispatch.(:from_timeline_transition_application_summary, summary, opts)
  end

  def route(
        %{model: "artifact_only_timeline_transition_application_summary"} = summary,
        opts,
        dispatch,
        _unsupported
      )
      when not is_map_key(summary, :schema_contract) do
    summary
    |> JsonNormalization.stringify_keys()
    |> then(&dispatch.(:from_timeline_transition_application_summary, &1, opts))
  end

  def route(
        %{"schema_contract" => "timeline_transition_application_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_timeline_transition_application_report, report, opts)

  def route(
        %{schema_contract: "timeline_transition_application_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_timeline_transition_application_report, &1, opts))

  def route(
        %{"schema_contract" => "approval_requirement.v1"} = requirement,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_approval_requirement, requirement, opts)

  def route(
        %{schema_contract: "approval_requirement.v1"} = requirement,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        requirement
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_approval_requirement, &1, opts))

  def route(
        %{"schema_contract" => "policy_decision.v1"} = decision,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_policy_decision, decision, opts)

  def route(%{schema_contract: "policy_decision.v1"} = decision, opts, dispatch, _unsupported),
    do:
      decision
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_policy_decision, &1, opts))

  def route(
        %{"schema_contract" => "branch_comparison_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_branch_comparison_report, report, opts)

  def route(
        %{schema_contract: "branch_comparison_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_branch_comparison_report, &1, opts))

  def route(
        %{"schema_contract" => "ranking_comparison_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_ranking_comparison_report, report, opts)

  def route(
        %{schema_contract: "ranking_comparison_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_ranking_comparison_report, &1, opts))

  def route(
        %{"schema_contract" => "score_term_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_score_term_report, report, opts)

  def route(%{schema_contract: "score_term_report.v1"} = report, opts, dispatch, _unsupported),
    do:
      report
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_score_term_report, &1, opts))

  def route(
        %{"schema_contract" => "objective_tradeoff_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_objective_tradeoff_report, report, opts)

  def route(
        %{schema_contract: "objective_tradeoff_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_objective_tradeoff_report, &1, opts))

  def route(
        %{"schema_contract" => "pareto_frontier_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_pareto_frontier_report, report, opts)

  def route(
        %{schema_contract: "pareto_frontier_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_pareto_frontier_report, &1, opts))

  def route(
        %{"schema_contract" => "schema_validation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_schema_validation_report, report, opts)

  def route(
        %{schema_contract: "schema_validation_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_schema_validation_report, &1, opts))

  def route(
        %{"schema_contract" => "schema_validation_batch_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_schema_validation_batch_report, report, opts)

  def route(
        %{schema_contract: "schema_validation_batch_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_schema_validation_batch_report, &1, opts))

  def route(
        %{"schema_contract" => "execution_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_execution_report, report, opts)

  def route(%{schema_contract: "execution_report.v1"} = report, opts, dispatch, _unsupported),
    do:
      report
      |> JsonNormalization.stringify_keys()
      |> then(&dispatch.(:from_execution_report, &1, opts))

  def route(
        %{"schema_contract" => "operational_readiness_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_operational_readiness_report, report, opts)

  def route(
        %{schema_contract: "operational_readiness_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_operational_readiness_report, &1, opts))

  def route(
        %{"schema_contract" => "quality_gate_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do: dispatch.(:from_quality_gate_report, report, opts)

  def route(
        %{schema_contract: "quality_gate_report.v1"} = report,
        opts,
        dispatch,
        _unsupported
      ),
      do:
        report
        |> JsonNormalization.stringify_keys()
        |> then(&dispatch.(:from_quality_gate_report, &1, opts))

  def route(%{} = artifact, _opts, _dispatch, unsupported) do
    contract = unsupported.(:contract, artifact)

    raise ArgumentError,
          "unsupported Cadence import artifact contract #{inspect(contract)}; " <>
            "supported contracts: #{unsupported.(:supported, nil)}"
  end

  def route(_artifact, _opts, _dispatch, _unsupported) do
    raise ArgumentError, "Cadence import artifact must be a map"
  end
end
