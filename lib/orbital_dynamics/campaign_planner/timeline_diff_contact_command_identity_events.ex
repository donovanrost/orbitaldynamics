defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCommandIdentityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffContactIdentityEventPayload

  def timeline_diff_changed_contact_identity_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      (callback!(callbacks, :timeline_diff_changed_downlink?).(row) or
         callback!(callbacks, :timeline_diff_changed_contact?).(row)) and
      TimelineDiffContactCommandIdentityFields.contact_identity_mismatch?(row, callbacks) and
      not callback!(callbacks, :timeline_diff_changed_contact_gap?).(row) and
      not callback!(callbacks, :timeline_diff_changed_link_quality_gap?).(row)
  end

  def timeline_diff_changed_contact_identity_events(row, source_path, callbacks) do
    if timeline_diff_changed_contact_identity_pressure_row?(row, callbacks) do
      [TimelineDiffContactIdentityEventPayload.build(row, source_path, callbacks)]
    else
      []
    end
  end

  def timeline_diff_changed_command_identity_pressure_row?(row, callbacks) do
    TimelineDiffCommandIdentityEvents.timeline_diff_changed_command_identity_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_command_identity_events(row, source_path, callbacks) do
    TimelineDiffCommandIdentityEvents.timeline_diff_changed_command_identity_events(
      row,
      source_path,
      callbacks
    )
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
