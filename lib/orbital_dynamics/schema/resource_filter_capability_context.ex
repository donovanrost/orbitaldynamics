defmodule OrbitalDynamics.Schema.ResourceFilterCapabilityContext do
  @moduledoc false

  def resource_filter_report_model_limits do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def resource_filter_policy_fields do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_filter_policy_fields)
  end

  def resource_filter_availability_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_availability_aliases)
  end

  def resource_filter_degraded_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_degraded_aliases)
  end

  def resource_filter_margin_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_margin_aliases)
  end

  def resource_filter_power_margin_source_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_power_margin_source_aliases)
  end

  def resource_filter_availability_true_tokens do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_availability_true_tokens)
  end

  def resource_filter_availability_false_tokens do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_availability_false_tokens)
  end

  def resource_filter_provider_direction_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  def resource_filter_station_calendar_direction_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:station_calendar_direction_aliases)
  end

  def resource_filter_provider_result_map_value_keys do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:provider_result_map_value_keys)
  end

  def resource_filter_candidate_stable_identity_fields do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:candidate_stable_identity_fields)
  end

  def resource_filter_station_calendar_id_list_fields do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:station_calendar_id_list_fields)
  end

  def resource_filter_suppression_reasons do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:suppression_reasons)
  end

  def resource_filter_row_review_statuses do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:row_review_statuses)
  end

  def resource_filter_report_assumptions_json_schema do
    OrbitalDynamics.Schema.ResourceFilterReportJsonSchema.assumptions_from_context(
      &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      &resource_filter_policy_fields/0,
      &resource_filter_availability_aliases/0,
      &resource_filter_degraded_aliases/0,
      &resource_filter_margin_aliases/0,
      &resource_filter_power_margin_source_aliases/0,
      &resource_filter_availability_true_tokens/0,
      &resource_filter_availability_false_tokens/0,
      &resource_filter_provider_direction_aliases/0,
      &resource_filter_station_calendar_direction_aliases/0,
      &resource_filter_provider_result_map_value_keys/0,
      &resource_filter_candidate_stable_identity_fields/0,
      &resource_filter_station_calendar_id_list_fields/0,
      &resource_filter_suppression_reasons/0,
      &resource_filter_row_review_statuses/0
    )
  end
end
