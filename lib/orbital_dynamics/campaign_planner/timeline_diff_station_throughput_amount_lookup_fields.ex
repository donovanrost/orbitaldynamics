defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputAmountLookupFields do
  @moduledoc false

  def explicit_actual_mb(row, callbacks) do
    [
      row["actual_throughput_mb"],
      row["replacement_actual_throughput_mb"],
      get_in(row, ["replacement_activity_context", "actual_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "actual_throughput_mb"]),
      row["source_actual_throughput_mb"],
      get_in(row, ["source_activity_context", "actual_throughput_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "actual_throughput_mb"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  def explicit_expected_mb(row, callbacks) do
    [
      row["expected_throughput_mb"],
      row["estimated_throughput_mb"],
      row["planned_throughput_mb"],
      row["planned_estimated_throughput_mb"],
      row["estimated_downlink_mb"],
      row["planned_downlink_mb"],
      row["required_downlink_mb"],
      row["required_data_volume_mb"],
      row["replacement_expected_throughput_mb"],
      row["replacement_estimated_throughput_mb"],
      row["replacement_planned_throughput_mb"],
      row["replacement_planned_estimated_throughput_mb"],
      row["replacement_estimated_downlink_mb"],
      row["replacement_planned_downlink_mb"],
      row["replacement_required_downlink_mb"],
      row["replacement_required_data_volume_mb"],
      get_in(row, ["replacement_activity_context", "expected_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "estimated_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "planned_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "planned_estimated_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "estimated_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "planned_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "required_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "required_data_volume_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "expected_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "estimated_throughput_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "planned_throughput_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "planned_estimated_throughput_mb"
      ]),
      get_in(row, ["replacement_activity_context", "throughput_model", "estimated_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "planned_downlink_mb"]),
      get_in(row, ["replacement_activity_context", "throughput_model", "required_downlink_mb"]),
      get_in(row, [
        "replacement_activity_context",
        "throughput_model",
        "required_data_volume_mb"
      ]),
      row["source_expected_throughput_mb"],
      row["source_estimated_throughput_mb"],
      row["source_planned_throughput_mb"],
      row["source_planned_estimated_throughput_mb"],
      row["source_estimated_downlink_mb"],
      row["source_planned_downlink_mb"],
      row["source_required_downlink_mb"],
      row["source_required_data_volume_mb"],
      get_in(row, ["source_activity_context", "expected_throughput_mb"]),
      get_in(row, ["source_activity_context", "estimated_throughput_mb"]),
      get_in(row, ["source_activity_context", "planned_throughput_mb"]),
      get_in(row, ["source_activity_context", "planned_estimated_throughput_mb"]),
      get_in(row, ["source_activity_context", "estimated_downlink_mb"]),
      get_in(row, ["source_activity_context", "planned_downlink_mb"]),
      get_in(row, ["source_activity_context", "required_downlink_mb"]),
      get_in(row, ["source_activity_context", "required_data_volume_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "expected_throughput_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "estimated_throughput_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "planned_throughput_mb"]),
      get_in(row, [
        "source_activity_context",
        "throughput_model",
        "planned_estimated_throughput_mb"
      ]),
      get_in(row, ["source_activity_context", "throughput_model", "estimated_downlink_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "planned_downlink_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "required_downlink_mb"]),
      get_in(row, ["source_activity_context", "throughput_model", "required_data_volume_mb"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
