defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCommandIdentityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCommandIdentityEventPayload
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityFields

  def timeline_diff_changed_command_identity_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      callback!(callbacks, :timeline_diff_changed_command?).(row) and
      TimelineDiffContactCommandIdentityFields.command_identity_mismatch?(row, callbacks) and
      not callback!(callbacks, :timeline_diff_changed_command_gap?).(row)
  end

  def timeline_diff_changed_command_identity_events(row, source_path, callbacks) do
    if timeline_diff_changed_command_identity_pressure_row?(row, callbacks) do
      [TimelineDiffCommandIdentityEventPayload.build(row, source_path, callbacks)]
    else
      []
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
