defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourceIdentityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourcePressureEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineTransitionApplicationPressureEvents

  def pressure_branch(row, source_path, index, policy, callbacks) do
    row = normalize_pressure_row(row, callbacks)

    row
    |> pressure_events(source_path, policy, callbacks)
    |> Enum.map(fn event ->
      status = row["diff_status"] || "review"

      identity =
        row["source_activity_id"] || row["timeline_id"] || event["target_id"] || event["type"] ||
          index

      %{
        "id" =>
          "derived_timeline_diff_#{callback!(callbacks, :branch_id_fragment).(status)}_#{callback!(callbacks, :branch_id_fragment).(identity)}",
        "label" => "Derived timeline diff #{status} #{identity}",
        "events" => [event],
        "metadata" =>
          %{
            "derived_source" => source_path,
            "timeline_id" => row["timeline_id"],
            "diff_status" => row["diff_status"],
            "application_status" => row["application_status"],
            "selected_activity_source" => row["selected_activity_source"]
          }
          |> callback!(callbacks, :compact_map).()
      }
    end)
  end

  def pressure_events(row, source_path, policy, callbacks) do
    events =
      cond do
        callback!(callbacks, :timeline_diff_removed_pressure_row?).(row) ->
          callback!(callbacks, :timeline_diff_removed_events).(row, source_path)

        callback!(callbacks, :timeline_diff_changed_downlink_pressure_row?).(row) ->
          [callback!(callbacks, :timeline_diff_changed_downlink_event).(row, source_path)] ++
            TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_contact_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffStationThroughputEvents.timeline_diff_changed_station_throughput_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_events(
              row,
              source_path,
              callbacks
            ) ++
            callback!(callbacks, :timeline_diff_changed_collection_latency_events).(
              row,
              source_path
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
              row,
              source_path,
              callbacks
            )

        callback!(callbacks, :timeline_diff_changed_contact_pressure_row?).(row) ->
          [callback!(callbacks, :timeline_diff_changed_contact_event).(row, source_path)] ++
            TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_contact_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffStationThroughputEvents.timeline_diff_changed_station_throughput_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_events(
              row,
              source_path,
              callbacks
            ) ++
            callback!(callbacks, :timeline_diff_changed_collection_latency_events).(
              row,
              source_path
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
              row,
              source_path,
              callbacks
            )

        callback!(callbacks, :timeline_diff_changed_observation_pressure_row?).(row, policy) ->
          callback!(callbacks, :timeline_diff_changed_observation_events).(
            row,
            source_path,
            policy
          ) ++
            TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            callback!(callbacks, :timeline_diff_changed_collection_latency_events).(
              row,
              source_path
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
              row,
              source_path,
              callbacks
            )

        callback!(callbacks, :timeline_diff_changed_command_pressure_row?).(row) ->
          [callback!(callbacks, :timeline_diff_changed_command_event).(row, source_path)] ++
            TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_command_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
              row,
              source_path,
              callbacks
            )

        callback!(callbacks, :timeline_diff_changed_maneuver_pressure_row?).(row) ->
          callback!(callbacks, :timeline_diff_changed_maneuver_events).(row, source_path) ++
            TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
              row,
              source_path,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
              row,
              source_path,
              policy,
              callbacks
            ) ++
            TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
              row,
              source_path,
              callbacks
            )

        TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_pressure_row?(
          row,
          policy,
          callbacks
        ) ->
          TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
            row,
            source_path,
            policy,
            callbacks
          )

        TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_pressure_row?(
          row,
          callbacks
        ) ->
          TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
            row,
            source_path,
            callbacks
          )

        TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_command_identity_pressure_row?(
          row,
          callbacks
        ) ->
          TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_command_identity_events(
            row,
            source_path,
            callbacks
          ) ++
            TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
              row,
              source_path,
              callbacks
            )

        TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_pressure_row?(
          row,
          callbacks
        ) ->
          TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
            row,
            source_path,
            callbacks
          )

        TimelineDiffStationThroughputEvents.timeline_diff_changed_station_throughput_pressure_row?(
          row,
          policy,
          callbacks
        ) ->
          TimelineDiffStationThroughputEvents.timeline_diff_changed_station_throughput_events(
            row,
            source_path,
            policy,
            callbacks
          )

        TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_pressure_row?(
          row,
          callbacks
        ) ->
          TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_events(
            row,
            source_path,
            callbacks
          )

        TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_contact_identity_pressure_row?(
          row,
          callbacks
        ) ->
          TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_contact_identity_events(
            row,
            source_path,
            callbacks
          )

        callback!(callbacks, :timeline_diff_changed_collection_latency_pressure_row?).(row) ->
          callback!(callbacks, :timeline_diff_changed_collection_latency_events).(
            row,
            source_path
          )

        true ->
          []
      end

    (events ++
       TimelineTransitionApplicationPressureEvents.timeline_transition_application_pressure_events(
         row,
         source_path,
         callbacks
       ))
    |> Enum.map(&Map.merge(&1, application_context(row, callbacks)))
    |> Enum.map(&callback!(callbacks, :compact_map).(&1))
  end

  defp normalize_pressure_row(row, callbacks) do
    row
    |> normalize_pressure_field("diff_status", callbacks)
    |> normalize_pressure_field("source_status", callbacks)
    |> normalize_pressure_field("replacement_status", callbacks)
    |> normalize_pressure_field("source_activity_type", callbacks)
    |> normalize_pressure_field("replacement_activity_type", callbacks)
    |> normalize_pressure_field("source_direction", callbacks)
    |> normalize_pressure_field("replacement_direction", callbacks)
    |> normalize_changed_fields(callbacks)
    |> normalize_activity_context("source_activity_context", callbacks)
    |> normalize_activity_context("replacement_activity_context", callbacks)
  end

  defp normalize_pressure_field(row, field, callbacks) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, callback!(callbacks, :normalized_status_token).(value))
    end
  end

  defp normalize_changed_fields(%{"changed_fields" => fields} = row, callbacks)
       when is_list(fields) do
    fields =
      fields
      |> Enum.map(&callback!(callbacks, :normalized_status_token).(&1))
      |> Enum.reject(&(&1 in [nil, ""]))

    Map.put(row, "changed_fields", fields)
  end

  defp normalize_changed_fields(row, _callbacks), do: row

  defp normalize_activity_context(row, field, callbacks) do
    case Map.get(row, field) do
      %{} = context ->
        context =
          context
          |> callback!(callbacks, :stringify_keys).()
          |> normalize_pressure_field("type", callbacks)
          |> normalize_pressure_field("activity_type", callbacks)
          |> normalize_pressure_field("direction", callbacks)
          |> normalize_pressure_field("status", callbacks)

        Map.put(row, field, context)

      _context ->
        row
    end
  end

  defp application_context(row, callbacks) do
    %{
      "approval_status" => row["approval_status"],
      "application_status" => row["application_status"],
      "selected_activity_source" => row["selected_activity_source"],
      "selected_activity" => row["selected_activity"],
      "source_timeline_application" => row["source_timeline_application"],
      "timeline_identity_collision" => row["timeline_identity_collision"],
      "duplicate_timeline_identity_scope" => row["duplicate_timeline_identity_scope"],
      "source_duplicate_activity_count" => row["source_duplicate_activity_count"],
      "replacement_duplicate_activity_count" => row["replacement_duplicate_activity_count"],
      "source_duplicate_activity_ids" => row["source_duplicate_activity_ids"],
      "replacement_duplicate_activity_ids" => row["replacement_duplicate_activity_ids"],
      "source_duplicate_activities" => row["source_duplicate_activities"],
      "replacement_duplicate_activities" => row["replacement_duplicate_activities"],
      "policy_classification" => row["policy_classification"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "source_policy_decision" => row["source_policy_decision"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"]
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
