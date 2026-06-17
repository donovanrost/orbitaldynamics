defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingAssessment do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingConditionFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingConditionSeverity
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingEclipseFields

  def observation_lighting_factor(row, callbacks) do
    overlap_fraction = eclipse_overlap_fraction(row, callbacks)

    factor =
      cond do
        is_number(overlap_fraction) and overlap_fraction > 0.0 ->
          1.0 - callback!(callbacks, :clamp_unit_interval).(overlap_fraction)

        callback!(callbacks, :positive_number?).(eclipse_overlap_s(row, callbacks)) ->
          lighting_condition_factor(realized_lighting_condition(row, callbacks), callbacks) ||
            lighting_condition_factor(lighting_condition_detail(row, callbacks), callbacks) ||
            0.5

        factor = lighting_condition_factor(realized_lighting_condition(row, callbacks), callbacks) ->
          factor

        factor = lighting_condition_factor(lighting_condition_detail(row, callbacks), callbacks) ->
          factor

        true ->
          1.0
      end

    callback!(callbacks, :clamp_unit_interval).(factor)
  end

  def observation_lighting_evidence?(row, callbacks) do
    is_number(eclipse_overlap_fraction(row, callbacks)) or
      is_number(eclipse_overlap_s(row, callbacks)) or
      realized_lighting_condition(row, callbacks) not in [nil, ""] or
      lighting_condition_detail(row, callbacks) not in [nil, ""]
  end

  def observation_lighting_reasons(row, callbacks) do
    overlap_fraction = eclipse_overlap_fraction(row, callbacks)
    overlap_s = eclipse_overlap_s(row, callbacks)
    realized_condition = realized_lighting_condition(row, callbacks)
    detail = lighting_condition_detail(row, callbacks)

    []
    |> maybe_append_reason(true, "timeline_diff_changed_activity")
    |> maybe_append_reason(true, "timeline_diff_changed_observation_lighting")
    |> maybe_append_reason(
      lighting_condition_match_status(row, callbacks) == "mismatch",
      "lighting_condition_mismatch"
    )
    |> maybe_append_reason(
      is_number(overlap_fraction) and overlap_fraction > 0.0,
      "eclipse_overlap_fraction_positive"
    )
    |> maybe_append_reason(
      callback!(callbacks, :positive_number?).(overlap_s),
      "eclipse_overlap_duration_positive"
    )
    |> maybe_append_reason(
      lighting_condition_factor(realized_condition, callbacks) not in [nil, 1.0],
      "lighting_condition_#{realized_condition}"
    )
    |> maybe_append_reason(
      lighting_condition_factor(detail, callbacks) not in [nil, 1.0],
      "lighting_detail_#{detail}"
    )
    |> Enum.reverse()
  end

  def eclipse_overlap_fraction(row, callbacks) do
    TimelineDiffObservationLightingEclipseFields.eclipse_overlap_fraction(row, callbacks)
  end

  def eclipse_overlap_s(row, callbacks) do
    TimelineDiffObservationLightingEclipseFields.eclipse_overlap_s(row, callbacks)
  end

  defp lighting_condition_match_status(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_condition_match_status(row, callbacks)
  end

  defp realized_lighting_condition(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.realized_lighting_condition(row, callbacks)
  end

  defp lighting_condition_detail(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_condition_detail(row, callbacks)
  end

  defp lighting_condition_factor(status, callbacks) when is_binary(status) do
    TimelineDiffObservationLightingConditionSeverity.factor(status, callbacks)
  end

  defp lighting_condition_factor(_status, _callbacks), do: nil

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, _condition, _reason), do: reasons

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
