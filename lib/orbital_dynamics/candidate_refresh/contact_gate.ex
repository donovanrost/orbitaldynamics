defmodule OrbitalDynamics.CandidateRefresh.ContactGate do
  @moduledoc false

  alias OrbitalDynamics.Communications.{ContactAllocation, ContactFilter}

  def filter_candidates(candidates, refresh, refresh_ground_network) do
    ContactFilter.filter_candidates(
      candidates,
      refresh_ground_network.(refresh),
      approval_policy: Map.get(refresh, "approval_policy")
    )
  end

  def allocation_report(candidates, refresh, contact_filter_report, refresh_ground_network) do
    candidates
    |> allocation_candidates(contact_filter_report)
    |> ContactAllocation.report(refresh_ground_network.(refresh),
      source: "candidate_refresh.candidate_activities",
      policy: Map.get(refresh, "contact_allocation_policy", %{}),
      approval_policy: Map.get(refresh, "approval_policy")
    )
  end

  def apply_allocation(candidates, contact_allocation_report) do
    usable_contact_ids =
      contact_allocation_report
      |> Map.get("rows", [])
      |> Enum.filter(&(&1["effective_allocation_status"] == "allocated"))
      |> Enum.map(& &1["contact_id"])
      |> MapSet.new()

    allocation_contact_ids =
      contact_allocation_report
      |> Map.get("rows", [])
      |> Enum.map(& &1["contact_id"])
      |> MapSet.new()

    Enum.split_with(candidates, fn candidate ->
      contact_id = candidate_contact_id(candidate)

      is_nil(contact_id) or
        not MapSet.member?(allocation_contact_ids, contact_id) or
        MapSet.member?(usable_contact_ids, contact_id)
    end)
  end

  defp allocation_candidates(candidates, contact_filter_report) do
    contact_filter_report
    |> Map.get("suppressed_candidates", [])
    |> Enum.filter(&candidate_contact?/1)
    |> then(&(candidates ++ &1))
  end

  defp candidate_contact_id(candidate) do
    if candidate_contact?(candidate) do
      Map.get(candidate, "id") || Map.get(candidate, "contact_id") ||
        Map.get(candidate, "activity_id")
    end
  end

  defp candidate_contact?(%{"type" => "contact"}), do: true
  defp candidate_contact?(%{"type" => "downlink"}), do: true
  defp candidate_contact?(%{"type" => "planned_contact"}), do: true

  defp candidate_contact?(%{"direction" => direction})
       when direction in ["downlink", "uplink", "command", "tracking"],
       do: true

  defp candidate_contact?(_candidate), do: false
end
