defmodule OrbitalDynamics.CampaignPlanner.ObjectiveContactIdentifiers do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ContactAllocationPressureBranches
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def source_contact_ids(row), do: source_contact_ids(row, callbacks())

  def source_contact_ids(row, callbacks) do
    [
      row["contact_ids"],
      row["contact_id"],
      row["contacts"],
      row["contact"],
      row["required_contact_ids"],
      row["required_contact_id"],
      row["required_contacts"],
      row["required_contact"],
      row["required_downlink_contact_ids"],
      row["required_downlink_contact_id"],
      row["required_downlink_contacts"],
      row["required_downlink_contact"],
      row["planned_contact_ids"],
      row["planned_contact_id"],
      row["planned_contacts"],
      row["planned_contact"],
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["satisfied_contact_ids"],
      row["satisfied_contact_id"],
      row["candidate_contact_ids"],
      row["candidate_contact_id"],
      row["source_contact_ids"],
      row["source_contact_id"],
      row["missed_contact_ids"],
      row["missed_contact_id"],
      row["missed_downlink_activity_ids"],
      row["missed_downlink_activity_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["satisfied_contacts"],
      row["satisfied_contact"],
      row["candidate_contacts"],
      row["candidate_contact"],
      row["source_contacts"],
      row["source_contact"],
      row["missed_contacts"],
      row["missed_contact"],
      row["missed_downlinks"],
      row["missed_downlink"],
      row["downlink_activities"],
      row["downlink_activity"]
    ]
    |> contact_ids(callbacks)
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def contact_count(row, fields), do: contact_count(row, fields, callbacks())

  def contact_count(row, fields, callbacks) do
    case contact_ids(contact_values(row, fields), callbacks) do
      [] -> nil
      ids -> length(ids)
    end
  end

  def contact_values(row, fields) do
    fields
    |> Enum.flat_map(fn field -> List.flatten([Map.get(row, field)]) end)
    |> Enum.reject(&is_nil/1)
  end

  def contact_id(contact), do: contact_id(contact, callbacks())

  def contact_id(%{} = contact, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    contact_identity = Keyword.fetch!(callbacks, :contact_identity)

    contact
    |> stringify_keys.()
    |> contact_identity.()
  end

  def contact_id(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:encode_value)
    |> then(& &1.(value))
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      contact_identity: &ContactAllocationPressureBranches.contact_identity/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      encode_value: &ValueEncoding.encode_value/1
    ]
  end

  defp contact_ids(values, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    values
    |> List.flatten()
    |> Enum.map(&contact_id(&1, callbacks))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
