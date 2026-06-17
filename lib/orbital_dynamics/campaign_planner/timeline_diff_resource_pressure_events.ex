defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffResourcePressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourceAvailabilityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourceMarginEvents

  def timeline_diff_changed_resource_margin_pressure_row?(row, policy, callbacks) do
    TimelineDiffResourceMarginEvents.timeline_diff_changed_resource_margin_pressure_row?(
      row,
      policy,
      callbacks
    )
  end

  def timeline_diff_changed_resource_margin_events(row, source_path, policy, callbacks) do
    TimelineDiffResourceMarginEvents.timeline_diff_changed_resource_margin_events(
      row,
      source_path,
      policy,
      callbacks
    )
  end

  def timeline_diff_changed_resource_availability_pressure_row?(row, callbacks) do
    TimelineDiffResourceAvailabilityEvents.timeline_diff_changed_resource_availability_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_resource_availability_events(row, source_path, callbacks) do
    TimelineDiffResourceAvailabilityEvents.timeline_diff_changed_resource_availability_events(
      row,
      source_path,
      callbacks
    )
  end
end
