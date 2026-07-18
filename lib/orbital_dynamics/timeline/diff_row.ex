defmodule OrbitalDynamics.Timeline.DiffRow do
  @moduledoc false

  @executed_statuses ~w(completed partial executed)
  @protected_approval_statuses ~w(approved auto_approvable locked)
  def build(timeline_id, rank, source_matches, replacement_matches, callbacks)
      when is_list(source_matches) and is_list(replacement_matches) and
             (length(source_matches) > 1 or length(replacement_matches) > 1) and
             is_list(callbacks) do
    source_activity_ids = Enum.map(source_matches, & &1["activity_id"])
    replacement_activity_ids = Enum.map(replacement_matches, & &1["activity_id"])

    %{
      "id" => "timeline_diff:#{timeline_id}:duplicate_identity",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => "changed",
      "changed_fields" => ["timeline_identity_collision"],
      "timeline_identity_collision" => true,
      "duplicate_timeline_identity_scope" =>
        duplicate_timeline_identity_scope(source_matches, replacement_matches, callbacks),
      "source_duplicate_activity_count" => length(source_matches),
      "replacement_duplicate_activity_count" => length(replacement_matches),
      "source_duplicate_activity_ids" => source_activity_ids,
      "replacement_duplicate_activity_ids" => replacement_activity_ids,
      "source_duplicate_activities" => source_matches,
      "replacement_duplicate_activities" => replacement_matches,
      "scenario_id" =>
        first_present(source_matches ++ replacement_matches, "scenario_id", callbacks),
      "source_activity_id" => List.first(source_activity_ids),
      "replacement_activity_id" => List.first(replacement_activity_ids),
      "source_activity_type" => first_present(source_matches, "activity_type", callbacks),
      "replacement_activity_type" =>
        first_present(replacement_matches, "activity_type", callbacks),
      "source_spacecraft_id" => first_present(source_matches, "spacecraft_id", callbacks),
      "replacement_spacecraft_id" =>
        first_present(replacement_matches, "spacecraft_id", callbacks),
      "source_ground_station_id" => first_present(source_matches, "ground_station_id", callbacks),
      "replacement_ground_station_id" =>
        first_present(replacement_matches, "ground_station_id", callbacks),
      "source_target_id" => first_present(source_matches, "target_id", callbacks),
      "replacement_target_id" => first_present(replacement_matches, "target_id", callbacks),
      "source_source_window_id" => first_present(source_matches, "source_window_id", callbacks),
      "replacement_source_window_id" =>
        first_present(replacement_matches, "source_window_id", callbacks),
      "requires_operator_review" => true,
      "required_operator_action" => "review_duplicate_timeline_identity",
      "reason" =>
        "timeline identity #{timeline_id} matches #{length(source_matches)} source and #{length(replacement_matches)} replacement activities",
      "source_timeline_identity" => first_present(source_matches, "timeline_identity", callbacks),
      "replacement_timeline_identity" =>
        first_present(replacement_matches, "timeline_identity", callbacks)
    }
    |> Map.merge(
      diff_dependency_context("source", first_row(source_matches, callbacks), callbacks)
    )
    |> Map.merge(
      diff_dependency_context("replacement", first_row(replacement_matches, callbacks), callbacks)
    )
    |> Map.merge(diff_schedule_context("source", first_row(source_matches, callbacks), callbacks))
    |> Map.merge(
      diff_schedule_context("replacement", first_row(replacement_matches, callbacks), callbacks)
    )
    |> Map.merge(
      diff_protection_context("source", first_row(source_matches, callbacks), callbacks)
    )
    |> Map.merge(
      diff_protection_context("replacement", first_row(replacement_matches, callbacks), callbacks)
    )
    |> compact_map(callbacks)
  end

  def build(timeline_id, rank, [], [replacement], callbacks) when is_list(callbacks) do
    {required_operator_action, reason} = added_activity_review(replacement, callbacks)

    %{
      "id" => "timeline_diff:#{timeline_id}",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => "added",
      "replacement_activity_id" => replacement["activity_id"],
      "replacement_activity_type" => replacement["activity_type"],
      "replacement_spacecraft_id" => replacement["spacecraft_id"],
      "replacement_ground_station_id" => replacement["ground_station_id"],
      "replacement_target_id" => replacement["target_id"],
      "replacement_source_window_id" => replacement["source_window_id"],
      "scenario_id" => replacement["scenario_id"],
      "replacement_starts_at_s" => replacement["starts_at_s"],
      "replacement_ends_at_s" => replacement["ends_at_s"],
      "replacement_status" => replacement["status"],
      "replacement_approval_status" => replacement["approval_status"],
      "replacement_locked" => replacement["locked"],
      "status_transition" => status_transition(nil, replacement, callbacks),
      "approval_transition" => approval_transition(nil, replacement, callbacks),
      "changed_fields" => ["timeline_presence"],
      "requires_operator_review" => true,
      "required_operator_action" => required_operator_action,
      "reason" => reason,
      "replacement_activity_context" => diff_activity_context(replacement, callbacks),
      "replacement_timeline_identity" => replacement["timeline_identity"]
    }
    |> Map.merge(diff_dependency_context("replacement", replacement, callbacks))
    |> Map.merge(diff_schedule_context("replacement", replacement, callbacks))
    |> Map.merge(diff_protection_context("replacement", replacement, callbacks))
    |> Map.merge(diff_invalid_activity_input_context("replacement", replacement, callbacks))
    |> compact_map(callbacks)
  end

  def build(timeline_id, rank, [source], [], callbacks) when is_list(callbacks) do
    {required_operator_action, reason} = removed_activity_review(source, callbacks)

    %{
      "id" => "timeline_diff:#{timeline_id}",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => "removed",
      "source_activity_id" => source["activity_id"],
      "source_activity_type" => source["activity_type"],
      "source_spacecraft_id" => source["spacecraft_id"],
      "source_ground_station_id" => source["ground_station_id"],
      "source_target_id" => source["target_id"],
      "source_source_window_id" => source["source_window_id"],
      "scenario_id" => source["scenario_id"],
      "source_starts_at_s" => source["starts_at_s"],
      "source_ends_at_s" => source["ends_at_s"],
      "source_status" => source["status"],
      "source_approval_status" => source["approval_status"],
      "source_locked" => source["locked"],
      "status_transition" => status_transition(source, nil, callbacks),
      "approval_transition" => approval_transition(source, nil, callbacks),
      "changed_fields" => ["timeline_presence"],
      "requires_operator_review" => true,
      "required_operator_action" => required_operator_action,
      "reason" => reason,
      "source_activity_context" => diff_activity_context(source, callbacks),
      "source_timeline_identity" => source["timeline_identity"]
    }
    |> Map.merge(diff_dependency_context("source", source, callbacks))
    |> Map.merge(diff_schedule_context("source", source, callbacks))
    |> Map.merge(diff_protection_context("source", source, callbacks))
    |> Map.merge(diff_invalid_activity_input_context("source", source, callbacks))
    |> compact_map(callbacks)
  end

  def build(timeline_id, rank, [source], [replacement], callbacks) when is_list(callbacks) do
    changed_fields = changed_fields(source, replacement, callbacks)
    diff_status = if changed_fields == [], do: "unchanged", else: "changed"
    status_transition = status_transition(source, replacement, callbacks)
    approval_transition = approval_transition(source, replacement, callbacks)

    integrity_review? =
      timeline_integrity_review?(source, callbacks) or
        timeline_integrity_review?(replacement, callbacks)

    helper_application? =
      not preservation_sensitive_source?(source, callbacks) and
        safe_transition_application_provenance?(
          replacement,
          status_transition,
          approval_transition,
          changed_fields,
          callbacks
        )

    requires_review =
      integrity_review? or
        (diff_status == "changed" and
           not helper_application? and
           (review_significant_change?(changed_fields, callbacks) or
              preservation_sensitive_source?(source, callbacks)))

    {required_operator_action, reason} =
      if integrity_review? do
        {"review_timeline_integrity",
         diff_timeline_integrity_reason(source, replacement, callbacks)}
      else
        changed_activity_review(
          diff_status,
          requires_review,
          source,
          replacement,
          changed_fields,
          callbacks
        )
      end

    %{
      "id" => "timeline_diff:#{timeline_id}",
      "rank" => rank,
      "timeline_id" => timeline_id,
      "diff_status" => diff_status,
      "source_activity_id" => source["activity_id"],
      "replacement_activity_id" => replacement["activity_id"],
      "source_activity_type" => source["activity_type"],
      "replacement_activity_type" => replacement["activity_type"],
      "source_spacecraft_id" => source["spacecraft_id"],
      "replacement_spacecraft_id" => replacement["spacecraft_id"],
      "source_ground_station_id" => source["ground_station_id"],
      "replacement_ground_station_id" => replacement["ground_station_id"],
      "source_target_id" => source["target_id"],
      "replacement_target_id" => replacement["target_id"],
      "source_source_window_id" => source["source_window_id"],
      "replacement_source_window_id" => replacement["source_window_id"],
      "scenario_id" => replacement["scenario_id"] || source["scenario_id"],
      "source_starts_at_s" => source["starts_at_s"],
      "source_ends_at_s" => source["ends_at_s"],
      "replacement_starts_at_s" => replacement["starts_at_s"],
      "replacement_ends_at_s" => replacement["ends_at_s"],
      "start_delta_s" => delta(replacement["starts_at_s"], source["starts_at_s"], callbacks),
      "end_delta_s" => delta(replacement["ends_at_s"], source["ends_at_s"], callbacks),
      "source_status" => source["status"],
      "replacement_status" => replacement["status"],
      "source_approval_status" => source["approval_status"],
      "replacement_approval_status" => replacement["approval_status"],
      "source_locked" => source["locked"],
      "replacement_locked" => replacement["locked"],
      "status_transition" => status_transition,
      "approval_transition" => approval_transition,
      "changed_fields" => changed_fields,
      "requires_operator_review" => requires_review,
      "required_operator_action" => required_operator_action,
      "reason" => reason,
      "operator_action_reason" =>
        diff_transition_operator_action_reason(status_transition, approval_transition, callbacks),
      "source_activity_context" => diff_activity_context(source, callbacks),
      "replacement_activity_context" => diff_activity_context(replacement, callbacks),
      "source_timeline_identity" => source["timeline_identity"],
      "replacement_timeline_identity" => replacement["timeline_identity"]
    }
    |> Map.merge(diff_dependency_context("source", source, callbacks))
    |> Map.merge(diff_dependency_context("replacement", replacement, callbacks))
    |> Map.merge(diff_schedule_context("source", source, callbacks))
    |> Map.merge(diff_schedule_context("replacement", replacement, callbacks))
    |> Map.merge(diff_protection_context("source", source, callbacks))
    |> Map.merge(diff_protection_context("replacement", replacement, callbacks))
    |> Map.merge(diff_invalid_activity_input_context("source", source, callbacks))
    |> Map.merge(diff_invalid_activity_input_context("replacement", replacement, callbacks))
    |> compact_map(callbacks)
  end

  defp added_activity_review(%{"invalid_activity_input" => true} = replacement, _callbacks) do
    {
      "review_invalid_activity_input",
      "replacement timeline includes invalid activity input #{replacement["activity_id"]}: #{replacement["invalid_activity_input_reason"]}"
    }
  end

  defp added_activity_review(replacement, _callbacks) do
    {
      "review_added_activity",
      "replacement timeline adds activity #{replacement["activity_id"]}"
    }
  end

  defp removed_activity_review(%{"invalid_activity_input" => true} = source, _callbacks) do
    {
      "review_invalid_activity_input",
      "source timeline includes invalid activity input #{source["activity_id"]}: #{source["invalid_activity_input_reason"]}"
    }
  end

  defp removed_activity_review(%{"status" => status} = source, _callbacks)
       when status in @executed_statuses do
    {
      "review_removed_executed_activity",
      "replacement timeline removes executed activity #{source["activity_id"]}"
    }
  end

  defp removed_activity_review(source, _callbacks) do
    cond do
      source["locked"] ->
        {
          "review_removed_protected_activity",
          "replacement timeline removes locked activity #{source["activity_id"]}"
        }

      source["approval_status"] in @protected_approval_statuses ->
        {
          "review_removed_protected_activity",
          "replacement timeline removes approved activity #{source["activity_id"]}"
        }

      true ->
        {
          "review_removed_activity",
          "replacement timeline removes activity #{source["activity_id"]}"
        }
    end
  end

  defp changed_activity_review(
         "unchanged",
         _requires_review,
         source,
         replacement,
         changed_fields,
         callbacks
       ) do
    {
      diff_required_operator_action("unchanged", false, callbacks),
      diff_reason("unchanged", source, replacement, changed_fields, callbacks)
    }
  end

  defp changed_activity_review(
         "changed",
         true,
         %{"status" => status} = source,
         _replacement,
         changed_fields,
         _callbacks
       )
       when status in @executed_statuses do
    {
      "review_changed_executed_activity",
      "replacement timeline changes executed activity #{source["activity_id"]}: #{Enum.join(changed_fields, ",")}"
    }
  end

  defp changed_activity_review("changed", true, source, replacement, changed_fields, callbacks) do
    cond do
      source["locked"] ->
        {
          "review_changed_protected_activity",
          "replacement timeline changes locked activity #{source["activity_id"]}: #{Enum.join(changed_fields, ",")}"
        }

      approval_protected?(source, callbacks) ->
        {
          "review_changed_protected_activity",
          "replacement timeline changes approved activity #{source["activity_id"]}: #{Enum.join(changed_fields, ",")}"
        }

      true ->
        {
          diff_required_operator_action("changed", true, callbacks),
          diff_reason("changed", source, replacement, changed_fields, callbacks)
        }
    end
  end

  defp changed_activity_review("changed", false, source, replacement, changed_fields, callbacks) do
    {
      diff_required_operator_action("changed", false, callbacks),
      diff_reason("changed", source, replacement, changed_fields, callbacks)
    }
  end

  defp safe_transition_application_provenance?(
         replacement,
         status_transition,
         approval_transition,
         changed_fields,
         callbacks
       ) do
    case transition_application_provenance_from_activity(replacement, callbacks) do
      %{"helper" => "transition_activity_status"} = provenance ->
        safe_transition_application_provenance_field?(
          provenance,
          "status",
          status_transition,
          changed_fields,
          callbacks
        )

      %{"helper" => "transition_activity_approval_status"} = provenance ->
        safe_transition_application_provenance_field?(
          provenance,
          "approval_status",
          approval_transition,
          changed_fields,
          callbacks
        )

      %{"helper" => "apply_lifecycle_event"} = provenance ->
        safe_lifecycle_event_transition_application_provenance?(
          provenance,
          status_transition,
          approval_transition,
          changed_fields,
          callbacks
        )

      _other ->
        false
    end
  end

  defp safe_transition_application_provenance_field?(
         provenance,
         field,
         transition,
         changed_fields,
         callbacks
       )
       when is_map(transition) do
    changed_fields == [field] and
      safe_transition_application_provenance_values?(provenance, field, transition, callbacks)
  end

  defp safe_transition_application_provenance_field?(
         _provenance,
         _field,
         _transition,
         _changed_fields,
         _callbacks
       ),
       do: false

  defp safe_transition_application_provenance_values?(
         provenance,
         field,
         transition,
         _callbacks
       )
       when is_map(transition) do
    provenance["field"] == field and
      provenance["transition_type"] == transition["transition_type"] and
      provenance["from"] == transition["from"] and
      provenance["to"] == transition["to"] and
      provenance["transition_category"] == transition["transition_category"] and
      provenance["operator_action_reason"] == transition["operator_action_reason"] and
      provenance["requires_operator_review"] == false and
      transition["requires_operator_review"] == false
  end

  defp safe_lifecycle_event_transition_application_provenance?(
         provenance,
         status_transition,
         approval_transition,
         changed_fields,
         callbacks
       ) do
    not transition_requires_operator_review?(status_transition, callbacks) and
      not transition_requires_operator_review?(approval_transition, callbacks) and
      lifecycle_event_provenance_matches_transition?(
        provenance,
        status_transition,
        approval_transition,
        changed_fields,
        callbacks
      )
  end

  defp lifecycle_event_provenance_matches_transition?(
         provenance,
         %{} = status_transition,
         _approval_transition,
         changed_fields,
         callbacks
       ) do
    changed_fields == ["status"] and
      safe_transition_application_provenance_values?(
        provenance,
        "status",
        status_transition,
        callbacks
      )
  end

  defp lifecycle_event_provenance_matches_transition?(
         provenance,
         _status_transition,
         %{} = approval_transition,
         changed_fields,
         callbacks
       ) do
    changed_fields == ["approval_status"] and
      safe_transition_application_provenance_values?(
        provenance,
        "approval_status",
        approval_transition,
        callbacks
      )
  end

  defp lifecycle_event_provenance_matches_transition?(
         provenance,
         nil,
         nil,
         changed_fields,
         _callbacks
       ) do
    changed_fields == [] and
      provenance["field"] == "lifecycle_event" and
      provenance["requires_operator_review"] == false
  end

  defp transition_application_provenance_from_activity(
         %{
           "transition_application_provenance" => %{} = provenance
         },
         _callbacks
       ),
       do: provenance

  defp transition_application_provenance_from_activity(
         %{
           "activity_context" => %{"transition_application_provenance" => %{} = provenance}
         },
         _callbacks
       ),
       do: provenance

  defp transition_application_provenance_from_activity(_activity, _callbacks), do: nil

  defp diff_transition_operator_action_reason(
         %{"requires_operator_review" => true, "operator_action_reason" => reason},
         _approval_transition,
         _callbacks
       )
       when is_binary(reason) and reason != "",
       do: reason

  defp diff_transition_operator_action_reason(
         _status_transition,
         %{"requires_operator_review" => true, "operator_action_reason" => reason},
         _callbacks
       )
       when is_binary(reason) and reason != "",
       do: reason

  defp diff_transition_operator_action_reason(
         _status_transition,
         _approval_transition,
         _callbacks
       ),
       do: nil

  def put_transition_decision(row, callbacks) when is_list(callbacks) do
    {decision, reason} = transition_decision_for_diff_row(row, callbacks)

    row
    |> Map.put("transition_decision", decision)
    |> Map.put("transition_decision_reason", reason)
  end

  defp diff_timeline_integrity_reason(source, replacement, callbacks) do
    source? = timeline_integrity_review?(source, callbacks)
    replacement? = timeline_integrity_review?(replacement, callbacks)

    cond do
      source? and replacement? ->
        "source and replacement timeline activities require integrity review"

      source? ->
        "source timeline activity requires integrity review"

      replacement? ->
        "replacement timeline activity requires integrity review"
    end
  end

  defp transition_decision_for_diff_row(
         %{
           "diff_status" => "unchanged",
           "requires_operator_review" => false
         },
         _callbacks
       ) do
    {"none", "timeline_unchanged"}
  end

  defp transition_decision_for_diff_row(
         %{
           "diff_status" => diff_status,
           "source_protection_decision" => %{"protection_decision" => "preserve"} = protection
         },
         _callbacks
       )
       when diff_status in ["changed", "removed"] do
    {"preserve_source", Map.get(protection, "reason", "source_activity_requires_preservation")}
  end

  defp transition_decision_for_diff_row(
         %{"requires_operator_review" => true} = row,
         _callbacks
       ) do
    {"review", row["operator_action_reason"] || row["reason"] || "operator_review_required"}
  end

  defp transition_decision_for_diff_row(%{"diff_status" => "changed"} = row, _callbacks) do
    {"record", row["operator_action_reason"] || row["reason"] || "record_timeline_change"}
  end

  defp transition_decision_for_diff_row(row, _callbacks) do
    {"review", row["operator_action_reason"] || row["reason"] || "operator_review_required"}
  end

  defp diff_activity_context(row, callbacks) do
    Map.get(row, "activity_context") ||
      row
      |> Map.put("id", row["activity_id"])
      |> activity_context(callbacks)
  end

  defp first_row([row | _rows], _callbacks), do: row
  defp first_row([], _callbacks), do: %{}

  defp first_present(rows, field, _callbacks) do
    Enum.find_value(rows, &Map.get(&1, field))
  end

  defp duplicate_timeline_identity_scope(source_matches, replacement_matches, _callbacks) do
    case {length(source_matches) > 1, length(replacement_matches) > 1} do
      {true, true} -> "source_and_replacement"
      {true, false} -> "source"
      {false, true} -> "replacement"
      {false, false} -> "none"
    end
  end

  defp activity_context(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :activity_context), [value])

  defp approval_protected?(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :approval_protected?), [value])

  defp approval_transition(source, replacement, callbacks),
    do: apply(Keyword.fetch!(callbacks, :approval_transition), [source, replacement])

  defp changed_fields(source, replacement, callbacks),
    do: apply(Keyword.fetch!(callbacks, :changed_fields), [source, replacement])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])

  defp delta(left, right, callbacks),
    do: apply(Keyword.fetch!(callbacks, :delta), [left, right])

  defp diff_dependency_context(prefix, row, callbacks),
    do: apply(Keyword.fetch!(callbacks, :diff_dependency_context), [prefix, row])

  defp diff_invalid_activity_input_context(prefix, row, callbacks),
    do: apply(Keyword.fetch!(callbacks, :diff_invalid_activity_input_context), [prefix, row])

  defp diff_protection_context(prefix, row, callbacks),
    do: apply(Keyword.fetch!(callbacks, :diff_protection_context), [prefix, row])

  defp diff_schedule_context(prefix, row, callbacks),
    do: apply(Keyword.fetch!(callbacks, :diff_schedule_context), [prefix, row])

  defp preservation_sensitive_source?(source, callbacks),
    do: apply(Keyword.fetch!(callbacks, :preservation_sensitive_source?), [source])

  defp review_significant_change?(fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :review_significant_change?), [fields])

  defp status_transition(source, replacement, callbacks),
    do: apply(Keyword.fetch!(callbacks, :status_transition), [source, replacement])

  defp timeline_integrity_review?(row, callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_integrity_review?), [row])

  defp diff_required_operator_action(status, requires_review, callbacks),
    do:
      apply(
        Keyword.fetch!(callbacks, :diff_required_operator_action),
        [status, requires_review]
      )

  defp diff_reason(status, source, replacement, fields, callbacks),
    do: apply(Keyword.fetch!(callbacks, :diff_reason), [status, source, replacement, fields])

  defp transition_requires_operator_review?(transition, callbacks),
    do: apply(Keyword.fetch!(callbacks, :transition_requires_operator_review?), [transition])
end
