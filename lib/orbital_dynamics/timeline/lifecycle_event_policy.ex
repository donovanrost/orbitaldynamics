defmodule OrbitalDynamics.Timeline.LifecycleEventPolicy do
  @moduledoc false

  def replacement_activity!(
        source_activity,
        event,
        normalize_lifecycle_event,
        maybe_put_lifecycle_status_unless_preserved
      ) do
    case normalize_lifecycle_event.(event) do
      "approve" ->
        source_activity
        |> Map.put("approval_status", "approved")
        |> maybe_put_lifecycle_status_unless_preserved.("approved")

      "reject" ->
        Map.put(source_activity, "approval_status", "rejected")

      "lock" ->
        source_activity
        |> Map.put("approval_status", "locked")
        |> Map.put("locked", true)
        |> maybe_put_lifecycle_status_unless_preserved.("locked")

      "start_execution" ->
        Map.put(source_activity, "status", "executing")

      "record_execution" ->
        Map.put(source_activity, "status", "executed")

      "record_completion" ->
        Map.put(source_activity, "status", "completed")

      "record_partial" ->
        Map.put(source_activity, "status", "partial")

      "record_failure" ->
        Map.put(source_activity, "status", "failed")

      "record_miss" ->
        Map.put(source_activity, "status", "missed")

      "delay" ->
        Map.put(source_activity, "status", "delayed")

      "cancel" ->
        Map.put(source_activity, "status", "canceled")
    end
  end

  def review_transition(status_transition, approval_transition, requires_operator_review?) do
    Enum.find([status_transition, approval_transition], requires_operator_review?)
  end

  def provenance_field(status_transition, approval_transition) do
    cond do
      is_map(status_transition) -> "status"
      is_map(approval_transition) -> "approval_status"
      true -> "lifecycle_event"
    end
  end

  def provenance_transition(status_transition, approval_transition) do
    status_transition || approval_transition
  end
end
