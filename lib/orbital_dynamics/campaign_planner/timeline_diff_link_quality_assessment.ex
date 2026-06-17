defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityAssessment do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityFields

  def link_quality_gap?(row, callbacks) do
    link_quality_failure?(row, callbacks) or link_profile_mismatch?(row, callbacks)
  end

  def link_quality_reasons(row, callbacks) do
    []
    |> maybe_append_reason(true, "timeline_diff_changed_activity")
    |> maybe_append_reason(true, "timeline_diff_changed_link_quality")
    |> maybe_append_reason(
      callback!(callbacks, :timeline_diff_changed_carrier_lock).(row) == false,
      "carrier_lock_lost"
    )
    |> maybe_append_reason(
      callback!(callbacks, :timeline_diff_changed_symbol_lock).(row) == false,
      "symbol_lock_lost"
    )
    |> maybe_append_reason(
      negative_link_margin?(callback!(callbacks, :timeline_diff_changed_link_margin_db).(row)),
      "negative_link_margin"
    )
    |> maybe_append_reason(
      link_quality_failure_status?(
        callback!(callbacks, :timeline_diff_changed_link_quality_status).(row)
      ),
      "link_quality_status_#{callback!(callbacks, :timeline_diff_changed_link_quality_status).(row)}"
    )
    |> maybe_append_reason(link_profile_mismatch?(row, callbacks), "link_profile_mismatch")
    |> Kernel.++(Enum.map(link_profile_mismatch_fields(row, callbacks), &"#{&1}_mismatch"))
    |> Enum.reverse()
  end

  def link_profile_mismatch_fields(row, callbacks) do
    string_mismatches =
      ["link_protocol", "frequency_band", "modulation", "coding_scheme", "polarization"]
      |> Enum.filter(
        &(TimelineDiffLinkQualityFields.link_profile_match_status(row, &1, callbacks) ==
            "mismatch")
      )

    if TimelineDiffLinkQualityFields.data_rate_match_status(row, callbacks) == "mismatch" do
      string_mismatches ++ ["data_rate"]
    else
      string_mismatches
    end
  end

  defp link_quality_failure?(row, callbacks) do
    callback!(callbacks, :timeline_diff_changed_carrier_lock).(row) == false or
      callback!(callbacks, :timeline_diff_changed_symbol_lock).(row) == false or
      negative_link_margin?(callback!(callbacks, :timeline_diff_changed_link_margin_db).(row)) or
      link_quality_failure_status?(
        callback!(callbacks, :timeline_diff_changed_link_quality_status).(row)
      )
  end

  defp link_profile_mismatch?(row, callbacks) do
    link_profile_mismatch_fields(row, callbacks) != []
  end

  defp link_quality_failure_status?(status) when is_binary(status) do
    status in [
      "below_threshold",
      "degraded",
      "failed",
      "failure",
      "link_failed",
      "lock_lost",
      "low_margin",
      "lost_lock",
      "no_lock",
      "poor",
      "unusable"
    ]
  end

  defp link_quality_failure_status?(_status), do: false

  defp negative_link_margin?(value), do: is_number(value) and value < 0.0

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, false, _reason), do: reasons

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
