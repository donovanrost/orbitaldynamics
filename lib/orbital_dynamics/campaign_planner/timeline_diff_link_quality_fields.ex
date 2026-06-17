defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityAssessment
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityDataRateFields

  def link_quality_gap?(row, callbacks) do
    TimelineDiffLinkQualityAssessment.link_quality_gap?(row, callbacks)
  end

  def link_quality_reasons(row, callbacks) do
    TimelineDiffLinkQualityAssessment.link_quality_reasons(row, callbacks)
  end

  def link_profile_mismatch_fields(row, callbacks) do
    TimelineDiffLinkQualityAssessment.link_profile_mismatch_fields(row, callbacks)
  end

  def link_profile_value(row, field, callbacks) do
    realized_link_profile_value(row, field, callbacks) ||
      planned_link_profile_value(row, field, callbacks)
  end

  def planned_link_profile_value(row, field, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "planned_#{field}",
      "source_planned_#{field}",
      "source_#{field}",
      ["source_activity_context", "planned_#{field}"],
      ["source_activity_context", field],
      ["source_activity_context", "link", field],
      ["source_activity_context", "communications", field],
      ["source_activity_context", "throughput_model", field]
    ])
  end

  def realized_link_profile_value(row, field, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "realized_#{field}",
      "replacement_realized_#{field}",
      "replacement_#{field}",
      ["replacement_activity_context", "realized_#{field}"],
      ["replacement_activity_context", field],
      ["replacement_activity_context", "link", field],
      ["replacement_activity_context", "communications", field],
      ["replacement_activity_context", "throughput_model", field]
    ])
  end

  def link_profile_match_status(row, field, callbacks) do
    callback!(callbacks, :timeline_diff_match_status).(
      planned_link_profile_value(row, field, callbacks),
      realized_link_profile_value(row, field, callbacks)
    )
  end

  def planned_data_rate_mbps(row, callbacks) do
    TimelineDiffLinkQualityDataRateFields.planned_data_rate_mbps(row, callbacks)
  end

  def realized_data_rate_mbps(row, callbacks) do
    TimelineDiffLinkQualityDataRateFields.realized_data_rate_mbps(row, callbacks)
  end

  def link_profile_data_rate_mbps(row, callbacks) do
    TimelineDiffLinkQualityDataRateFields.link_profile_data_rate_mbps(row, callbacks)
  end

  def data_rate_delta_mbps(row, callbacks) do
    TimelineDiffLinkQualityDataRateFields.data_rate_delta_mbps(row, callbacks)
  end

  def data_rate_match_status(row, callbacks) do
    TimelineDiffLinkQualityDataRateFields.data_rate_match_status(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
