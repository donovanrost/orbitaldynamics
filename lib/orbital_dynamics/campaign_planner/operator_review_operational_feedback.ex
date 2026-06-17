defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewOperationalFeedback do
  @moduledoc false

  def from_rows(rows, operational_timeline_rows, realized_feedback_rows, opts)
      when is_list(opts) do
    command_feedback = Keyword.fetch!(opts, :command_feedback)
    maneuver_feedback = Keyword.fetch!(opts, :maneuver_feedback)
    row_sets = row_sets(rows, operational_timeline_rows, realized_feedback_rows, opts)

    row_sets.contact
    |> from_contact_observation_rows(row_sets.observation, opts)
    |> Map.merge(command_feedback.(row_sets.command))
    |> Map.merge(maneuver_feedback.(row_sets.maneuver))
  end

  def from_contact_observation_rows(contact_rows, observation_rows, opts) when is_list(opts) do
    station_feedback_average = Keyword.fetch!(opts, :station_feedback_average)
    target_feedback_average = Keyword.fetch!(opts, :target_feedback_average)
    target_feedback_text = Keyword.fetch!(opts, :target_feedback_text)
    contact_success_value = Keyword.fetch!(opts, :contact_success_value)
    observation_success_value = Keyword.fetch!(opts, :observation_success_value)
    image_quality_score_value = Keyword.fetch!(opts, :image_quality_score_value)
    image_quality_status_value = Keyword.fetch!(opts, :image_quality_status_value)
    image_quality_source_value = Keyword.fetch!(opts, :image_quality_source_value)
    cloud_cover_fraction_value = Keyword.fetch!(opts, :cloud_cover_fraction_value)
    blur_score_value = Keyword.fetch!(opts, :blur_score_value)
    station_throughput_value = Keyword.fetch!(opts, :station_throughput_value)
    station_downlink_demand_feedback = Keyword.fetch!(opts, :station_downlink_demand_feedback)

    %{
      "contact_success_rate" => station_feedback_average.(contact_rows, contact_success_value),
      "observation_success_rate" =>
        target_feedback_average.(observation_rows, observation_success_value),
      "image_quality_score" =>
        target_feedback_average.(observation_rows, image_quality_score_value),
      "image_quality_status" =>
        target_feedback_text.(observation_rows, image_quality_status_value),
      "image_quality_source" =>
        target_feedback_text.(observation_rows, image_quality_source_value),
      "cloud_cover_fraction" =>
        target_feedback_average.(observation_rows, cloud_cover_fraction_value),
      "blur_score" => target_feedback_average.(observation_rows, blur_score_value),
      "station_throughput_factor" =>
        station_feedback_average.(contact_rows, station_throughput_value),
      "downlink_demand_mb" => station_downlink_demand_feedback.(contact_rows)
    }
  end

  defp row_sets(rows, operational_timeline_rows, realized_feedback_rows, opts) do
    contact_feedback_row? = Keyword.fetch!(opts, :contact_feedback_row?)
    observation_feedback_row? = Keyword.fetch!(opts, :observation_feedback_row?)
    command_feedback_row? = Keyword.fetch!(opts, :command_feedback_row?)
    maneuver_feedback_row? = Keyword.fetch!(opts, :maneuver_feedback_row?)
    command_window_rows = Keyword.fetch!(opts, :command_window_rows)
    maneuver_review_rows = Keyword.fetch!(opts, :maneuver_review_rows)

    timeline_and_realized_rows = operational_timeline_rows ++ realized_feedback_rows

    %{
      contact: Enum.filter(timeline_and_realized_rows, contact_feedback_row?),
      observation: Enum.filter(timeline_and_realized_rows, observation_feedback_row?),
      command:
        rows
        |> command_window_rows.()
        |> Kernel.++(Enum.filter(operational_timeline_rows, command_feedback_row?))
        |> Kernel.++(Enum.filter(realized_feedback_rows, command_feedback_row?)),
      maneuver:
        rows
        |> maneuver_review_rows.()
        |> Kernel.++(Enum.filter(operational_timeline_rows, maneuver_feedback_row?))
        |> Kernel.++(Enum.filter(realized_feedback_rows, maneuver_feedback_row?))
    }
  end
end
