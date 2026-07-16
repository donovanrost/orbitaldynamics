defmodule OrbitalDynamics.CampaignPlanner.ObjectiveActivityIdentifiers do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermIdentifiers

  def source_observation_ids(row), do: source_observation_ids(row, callbacks())

  def source_observation_ids(row, callbacks) do
    [
      row["source_activity_ids"],
      row["source_activity_id"],
      row["source_activity"],
      row["source_activities"],
      row["activity_ids"],
      row["activity_id"],
      row["activity"],
      row["activities"],
      row["observation_activity_ids"],
      row["observation_activity_id"],
      row["observation"],
      row["observations"],
      row["source_observation_ids"],
      row["source_observation_id"],
      row["source_observation"],
      row["source_observations"],
      row["selected_activity_ids"],
      row["selected_observation_ids"],
      row["satisfied_activity_ids"],
      row["satisfied_observation_ids"],
      row["candidate_activity_ids"],
      row["candidate_observation_ids"],
      row["selected_activity"],
      row["selected_activities"],
      row["selected_observation"],
      row["selected_observations"],
      row["satisfied_activity"],
      row["satisfied_activities"],
      row["satisfied_observation"],
      row["satisfied_observations"],
      row["candidate_activity"],
      row["candidate_activities"],
      row["candidate_observation"],
      row["candidate_observations"]
    ]
    |> stable_activity_ids(callbacks)
  end

  def source_activity_id(row), do: source_activity_id(row, callbacks())

  def source_activity_id(row, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    first_stable_activity_id = Keyword.fetch!(callbacks, :first_stable_activity_id)

    [
      row["source_activity_id"],
      row["observation_activity_id"],
      row["selected_observation_id"],
      row["activity_id"]
    ]
    |> Enum.find(&stable_id_string?.(&1)) ||
      first_stable_activity_id.([
        row["source_observation"],
        row["selected_observation"],
        row["satisfied_observation"],
        row["candidate_observation"],
        row["source_observations"],
        row["selected_observations"],
        row["satisfied_observations"],
        row["candidate_observations"],
        row["selected_activity"],
        row["satisfied_activity"],
        row["candidate_activity"],
        row["activities"],
        row["selected_activities"],
        row["satisfied_activities"],
        row["candidate_activities"]
      ])
  end

  def source_activity_ids(row), do: source_activity_ids(row, callbacks())

  def source_activity_ids(row, callbacks) do
    [
      row["source_activity_ids"],
      row["source_activity_id"],
      row["source_activity"],
      row["source_activities"],
      row["observation_activity_ids"],
      row["observation_activity_id"],
      row["selected_activity_ids"],
      row["selected_activity"],
      row["selected_activities"],
      row["satisfied_activity_ids"],
      row["satisfied_activity"],
      row["satisfied_activities"],
      row["candidate_activity_ids"],
      row["candidate_activity"],
      row["candidate_activities"],
      row["selected_observation_ids"],
      row["selected_observation_id"],
      row["selected_observation"],
      row["selected_observations"],
      row["satisfied_observation_ids"],
      row["satisfied_observation"],
      row["satisfied_observations"],
      row["candidate_observation_ids"],
      row["candidate_observation"],
      row["candidate_observations"],
      row["source_observation"],
      row["source_observations"],
      row["activity_ids"],
      row["activities"],
      row["activity_id"]
    ]
    |> stable_activity_ids(callbacks)
  end

  def missed_downlink_activity_id(row), do: missed_downlink_activity_id(row, callbacks())

  def missed_downlink_activity_id(row, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    first_stable_activity_id = Keyword.fetch!(callbacks, :first_stable_activity_id)

    [
      row["missed_downlink_activity_id"],
      row["missed_contact_id"],
      row["selected_contact_id"],
      row["source_contact_id"],
      row["downlink_activity_id"]
    ]
    |> Enum.find(&stable_id_string?.(&1)) ||
      first_stable_activity_id.([
        row["missed_downlink"],
        row["missed_downlinks"],
        row["missed_contact"],
        row["missed_contacts"],
        row["selected_contact"],
        row["selected_contacts"],
        row["source_contact"],
        row["source_contacts"],
        row["downlink_activity"],
        row["downlink_activities"]
      ])
  end

  def missed_downlink_activity_ids(row), do: missed_downlink_activity_ids(row, callbacks())

  def missed_downlink_activity_ids(row, callbacks) do
    [
      row["missed_downlink_activity_ids"],
      row["missed_downlink_activity_id"],
      row["missed_downlinks"],
      row["missed_downlink"],
      row["missed_contact_ids"],
      row["missed_contact_id"],
      row["missed_contacts"],
      row["missed_contact"],
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["source_contact_ids"],
      row["source_contact_id"],
      row["source_contacts"],
      row["source_contact"],
      row["downlink_activity_ids"],
      row["downlink_activity_id"],
      row["downlink_activities"],
      row["downlink_activity"]
    ]
    |> stable_activity_ids(callbacks)
  end

  def tradeoff_source_activity_ids(row), do: tradeoff_source_activity_ids(row, callbacks())

  def tradeoff_source_activity_ids(row, callbacks) do
    [
      row["activity_ids"],
      row["activity_id"],
      row["activity"],
      row["activities"],
      row["source_activity_ids"],
      row["source_activity_id"],
      row["source_activity"],
      row["source_activities"],
      row["observation_activity_ids"],
      row["observation_activity_id"],
      row["observation"],
      row["observations"],
      row["source_observation_ids"],
      row["source_observation_id"],
      row["source_observation"],
      row["source_observations"],
      row["selected_activity_ids"],
      row["selected_activity"],
      row["selected_activities"],
      row["selected_observation_ids"],
      row["selected_observation_id"],
      row["selected_observation"],
      row["selected_observations"],
      row["satisfied_activity_ids"],
      row["satisfied_activity"],
      row["satisfied_activities"],
      row["satisfied_observation_ids"],
      row["satisfied_observation_id"],
      row["satisfied_observation"],
      row["satisfied_observations"],
      row["candidate_activity_ids"],
      row["candidate_activity"],
      row["candidate_activities"],
      row["candidate_observation_ids"],
      row["candidate_observation_id"],
      row["candidate_observation"],
      row["candidate_observations"],
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["satisfied_contact_ids"],
      row["satisfied_contact_id"],
      row["satisfied_contacts"],
      row["satisfied_contact"],
      row["candidate_contact_ids"],
      row["candidate_contact_id"],
      row["candidate_contacts"],
      row["candidate_contact"],
      row["source_contact_ids"],
      row["source_contact_id"],
      row["source_contacts"],
      row["source_contact"],
      row["missed_contact_ids"],
      row["missed_contact_id"],
      row["missed_contacts"],
      row["missed_contact"],
      row["missed_downlink_activity_ids"],
      row["missed_downlink_activity_id"],
      row["missed_downlinks"],
      row["missed_downlink"]
    ]
    |> stable_activity_ids(callbacks)
  end

  def tradeoff_source_activity_id(row), do: tradeoff_source_activity_id(row, callbacks())

  def tradeoff_source_activity_id(row, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    first_stable_activity_id = Keyword.fetch!(callbacks, :first_stable_activity_id)

    [
      row["source_activity_id"],
      row["observation_activity_id"],
      row["source_observation_id"],
      row["selected_observation_id"],
      row["satisfied_observation_id"],
      row["candidate_observation_id"],
      row["activity_id"]
    ]
    |> Enum.find(&stable_id_string?.(&1)) ||
      first_stable_activity_id.([
        row["source_activity"],
        row["source_activities"],
        row["source_observation"],
        row["selected_observation"],
        row["satisfied_observation"],
        row["candidate_observation"],
        row["source_observations"],
        row["selected_observations"],
        row["satisfied_observations"],
        row["candidate_observations"],
        row["observation"],
        row["observations"],
        row["activity"],
        row["selected_activity"],
        row["satisfied_activity"],
        row["candidate_activity"],
        row["activities"],
        row["selected_activities"],
        row["satisfied_activities"],
        row["candidate_activities"]
      ])
  end

  defp callbacks do
    [
      activity_id_values: &ScoreTermIdentifiers.activity_id_values/1,
      first_stable_activity_id: &ScoreTermIdentifiers.first_stable_activity_id/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1
    ]
  end

  defp stable_activity_ids(values, callbacks) do
    activity_id_values = Keyword.fetch!(callbacks, :activity_id_values)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    values
    |> Enum.flat_map(&activity_id_values.(&1))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end
end
