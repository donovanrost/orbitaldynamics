defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingAssessment do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingStatusClassification

  def factor(row, callbacks) do
    cond do
      pointing_mismatch?(row, callbacks) ->
        0.0

      pointing_failure_status?(
        TimelineDiffObservationPointingFields.pointing_status(row, callbacks)
      ) or
          pointing_failure_status?(
            TimelineDiffObservationPointingFields.attitude_status(row, callbacks)
          ) ->
        0.0

      pointing_degraded_status?(
        TimelineDiffObservationPointingFields.pointing_status(row, callbacks)
      ) or
          pointing_degraded_status?(
            TimelineDiffObservationPointingFields.attitude_status(row, callbacks)
          ) ->
        0.5

      true ->
        1.0
    end
  end

  def reasons(row, callbacks) do
    pointing_status = TimelineDiffObservationPointingFields.pointing_status(row, callbacks)
    attitude_status = TimelineDiffObservationPointingFields.attitude_status(row, callbacks)

    []
    |> maybe_append_reason(true, "timeline_diff_changed_activity")
    |> maybe_append_reason(true, "timeline_diff_changed_observation_pointing")
    |> maybe_append_reason(
      match_status(row, "pointing_target_match_status", callbacks) == "mismatch",
      "pointing_target_mismatch"
    )
    |> maybe_append_reason(
      match_status(row, "pointing_mode_match_status", callbacks) == "mismatch",
      "pointing_mode_mismatch"
    )
    |> maybe_append_reason(
      match_status(row, "attitude_target_match_status", callbacks) == "mismatch",
      "attitude_target_mismatch"
    )
    |> maybe_append_reason(
      match_status(row, "attitude_mode_match_status", callbacks) == "mismatch",
      "attitude_mode_mismatch"
    )
    |> maybe_append_reason(
      pointing_failure_status?(pointing_status) or pointing_degraded_status?(pointing_status),
      "pointing_status_#{pointing_status}"
    )
    |> maybe_append_reason(
      pointing_failure_status?(attitude_status) or pointing_degraded_status?(attitude_status),
      "attitude_status_#{attitude_status}"
    )
    |> Enum.reverse()
  end

  defp pointing_mismatch?(row, callbacks) do
    Enum.any?(
      [
        match_status(row, "pointing_target_match_status", callbacks),
        match_status(row, "pointing_mode_match_status", callbacks),
        match_status(row, "attitude_target_match_status", callbacks),
        match_status(row, "attitude_mode_match_status", callbacks)
      ],
      &(&1 == "mismatch")
    )
  end

  defp match_status(row, field, callbacks) do
    TimelineDiffObservationPointingFields.match_status(row, field, callbacks)
  end

  defp pointing_failure_status?(status),
    do: TimelineDiffObservationPointingStatusClassification.failure?(status)

  defp pointing_degraded_status?(status),
    do: TimelineDiffObservationPointingStatusClassification.degraded?(status)

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, _condition, _reason), do: reasons
end
