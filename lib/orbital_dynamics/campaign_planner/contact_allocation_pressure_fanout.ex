defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationPressureFanout do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactAllocationPressureBranches,
    ContactAllocationSuppressionPressureBranches,
    ProviderReservationPressureBranches,
    ScalarValues,
    ValueEncoding
  }

  def branches(row, source_path, callbacks \\ []) do
    row = normalize_contact_allocation_row(row)

    contact_allocation_callbacks = Keyword.get(callbacks, :contact_allocation)
    provider_reservation_callbacks = Keyword.get(callbacks, :provider_reservation)

    contact_allocation_branches =
      if is_list(contact_allocation_callbacks) do
        ContactAllocationPressureBranches.build(row, source_path, contact_allocation_callbacks)
      else
        ContactAllocationPressureBranches.build(row, source_path)
      end

    provider_reservation_branches =
      if is_list(provider_reservation_callbacks) do
        ProviderReservationPressureBranches.build(
          row,
          source_path,
          provider_reservation_callbacks
        )
      else
        ProviderReservationPressureBranches.build(row, source_path)
      end

    contact_allocation_branches ++
      provider_reservation_branches ++
      ContactAllocationSuppressionPressureBranches.contact(row, source_path) ++
      ContactAllocationSuppressionPressureBranches.resource(row, source_path)
  end

  defp normalize_contact_allocation_row(row) do
    row
    |> normalize_contact_allocation_status_field("allocation_status")
    |> normalize_contact_allocation_status_field("effective_allocation_status")
    |> normalize_contact_allocation_status_field("review_status")
    |> normalize_contact_allocation_status_field("approval_status")
    |> normalize_contact_allocation_policy_decision()
  end

  defp normalize_contact_allocation_status_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, ScalarValues.normalized_status_token(value))
    end
  end

  defp normalize_contact_allocation_policy_decision(%{"policy_decision" => %{} = decision} = row) do
    decision =
      decision
      |> ValueEncoding.stringify_keys()
      |> normalize_contact_allocation_status_field("classification")

    Map.put(row, "policy_decision", decision)
  end

  defp normalize_contact_allocation_policy_decision(row), do: row
end
