defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationProviderReservationRequestSummarySource do
  @moduledoc false

  @summary_model "artifact_only_contact_allocation_provider_reservation_request_summary"

  @row_keys [
    {"rows", :rows},
    {"provider_reservation_request_rows", :provider_reservation_request_rows},
    {"provider_reservation_review_rows", :provider_reservation_review_rows}
  ]

  @aggregate_excluded_keys [
    "provider_reservation_request_rows",
    "provider_reservation_review_rows"
  ]

  def source?(%{} = summary) do
    model(summary) == @summary_model and
      (row_source?(summary) or aggregate_source?(summary))
  end

  def source?(_summary), do: false

  defp row_source?(summary) do
    Enum.any?(@row_keys, fn {string_key, atom_key} ->
      is_list(value(summary, string_key, atom_key))
    end)
  end

  defp aggregate_source?(summary) do
    summary
    |> Map.keys()
    |> Enum.any?(fn key ->
      key = to_string(key)

      String.starts_with?(key, "provider_reservation_") and
        key not in @aggregate_excluded_keys
    end)
  end

  defp model(summary), do: value(summary, "model", :model)

  defp value(map, string_key, atom_key), do: Map.get(map, string_key) || Map.get(map, atom_key)
end
