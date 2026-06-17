defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourceIdentityEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffResourcePressureEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputEvents
  alias OrbitalDynamics.CampaignPlanner.TimelineTransitionApplicationPressureEvents

  def timeline_transition_application_pressure_events(row, source_path, callbacks) do
    TimelineTransitionApplicationPressureEvents.timeline_transition_application_pressure_events(
      row,
      source_path,
      callbacks
    )
  end

  def timeline_diff_changed_resource_identity_pressure_row?(row, callbacks) do
    TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_resource_identity_events(row, source_path, callbacks) do
    TimelineDiffResourceIdentityEvents.timeline_diff_changed_resource_identity_events(
      row,
      source_path,
      callbacks
    )
  end

  def timeline_diff_changed_contact_identity_pressure_row?(row, callbacks) do
    TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_contact_identity_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_contact_identity_events(row, source_path, callbacks) do
    TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_contact_identity_events(
      row,
      source_path,
      callbacks
    )
  end

  def timeline_diff_changed_command_identity_pressure_row?(row, callbacks) do
    TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_command_identity_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_command_identity_events(row, source_path, callbacks) do
    TimelineDiffContactCommandIdentityEvents.timeline_diff_changed_command_identity_events(
      row,
      source_path,
      callbacks
    )
  end

  def timeline_diff_changed_link_quality_pressure_row?(row, callbacks) do
    TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_link_quality_events(row, source_path, callbacks) do
    TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_events(
      row,
      source_path,
      callbacks
    )
  end

  def timeline_diff_changed_link_quality_gap?(row, callbacks) do
    TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_gap?(row, callbacks)
  end

  def timeline_diff_changed_station_throughput_pressure_row?(row, policy, callbacks) do
    TimelineDiffStationThroughputEvents.timeline_diff_changed_station_throughput_pressure_row?(
      row,
      policy,
      callbacks
    )
  end

  def timeline_diff_changed_station_throughput_events(row, source_path, policy, callbacks) do
    TimelineDiffStationThroughputEvents.timeline_diff_changed_station_throughput_events(
      row,
      source_path,
      policy,
      callbacks
    )
  end

  def timeline_diff_changed_resource_margin_pressure_row?(row, policy, callbacks) do
    TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_pressure_row?(
      row,
      policy,
      callbacks
    )
  end

  def timeline_diff_changed_resource_margin_events(row, source_path, policy, callbacks) do
    TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_margin_events(
      row,
      source_path,
      policy,
      callbacks
    )
  end

  def timeline_diff_changed_resource_availability_pressure_row?(row, callbacks) do
    TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_pressure_row?(
      row,
      callbacks
    )
  end

  def timeline_diff_changed_resource_availability_events(row, source_path, callbacks) do
    TimelineDiffResourcePressureEvents.timeline_diff_changed_resource_availability_events(
      row,
      source_path,
      callbacks
    )
  end
end
