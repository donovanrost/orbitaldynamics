defmodule OrbitalDynamics.Timeline.CandidateRejectionConditionPolicy do
  @moduledoc false

  def locked_overlap?(activity) do
    status =
      activity
      |> first_scalar_string(["schedule_conflict_status", "conflict_status"])
      |> normalized_token()

    status in ["locked_overlap", "overlaps_locked", "conflict_locked", "locked_conflict"]
  end

  def negative_margin?(activity, fields) do
    case first_number(activity, fields) do
      value when is_number(value) -> value < 0.0
      _value -> false
    end
  end

  def contact_too_short?(activity) do
    duration = activity_duration_s(activity)

    minimum =
      first_number(activity, ["minimum_duration_s", "min_duration_s", "required_duration_s"])

    is_number(duration) and is_number(minimum) and duration < minimum
  end

  def policy_blocked?(activity) do
    activity_status(activity) == "blocked_by_policy" or
      activity_approval_status(activity) == "blocked_by_policy"
  end

  def stale_state?(activity) do
    status =
      activity
      |> first_scalar_string(["freshness_status", "state_freshness_status"])
      |> normalized_token()

    status == "stale"
  end

  def model_incompatible?(activity) do
    status =
      activity
      |> first_scalar_string(["model_compatibility_status", "compatibility_status"])
      |> normalized_token()

    status in ["incompatible", "model_incompatible"]
  end

  def quality_gate_failed?(activity) do
    status =
      activity
      |> first_scalar_string([
        "quality_gate_status",
        "schema_validation_status",
        "validation_status"
      ])
      |> normalized_token()

    status in ["fail", "failed", "blocked"]
  end

  defp first_scalar_string(activity, fields) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, fields)
  end

  defp first_number(activity, fields) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      fields,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp activity_duration_s(activity) do
    OrbitalDynamics.Timeline.ActivityTimingPolicy.duration(activity)
  end

  defp activity_status(activity) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_status(
      activity,
      &OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.encode/1
    )
  end

  defp activity_approval_status(activity) do
    OrbitalDynamics.Timeline.LifecycleStateNormalizationPolicy.activity_approval_status(
      activity,
      &OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.encode/1
    )
  end

  def normalized_token(nil), do: nil

  def normalized_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end
end
