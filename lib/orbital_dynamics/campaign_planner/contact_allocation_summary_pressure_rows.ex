defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationSummaryPressureRows do
  @moduledoc false

  def rows(summary) do
    summary_trust_boundary = trust_boundary(summary)

    [
      "rows",
      "review_rows",
      "reservation_conflict_rows",
      "reservation_review_rows",
      "provider_reservation_request_rows",
      "provider_reservation_review_rows"
    ]
    |> Enum.flat_map(fn field ->
      summary
      |> Map.get(field, [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(fn row ->
        provider_scope = provider_reservation_row_scope(field)

        row
        |> Map.put_new("_source_report_trust_boundary", summary_trust_boundary)
        |> inherit_capacity_pack_summary_fields(summary)
        |> maybe_put_provider_reservation_request_status(
          provider_scope,
          summary["provider_reservation_request_status"]
        )
      end)
    end)
    |> Enum.uniq()
  end

  defp maybe_put_provider_reservation_request_status(row, nil, _request_status), do: row

  defp maybe_put_provider_reservation_request_status(row, provider_scope, request_status) do
    row
    |> Map.put_new("_provider_reservation_request_status", request_status)
    |> Map.put_new("_provider_reservation_row_scope", provider_scope)
  end

  defp provider_reservation_row_scope("provider_reservation_request_rows"), do: "request"
  defp provider_reservation_row_scope("provider_reservation_review_rows"), do: "review"
  defp provider_reservation_row_scope(_field), do: nil

  defp inherit_capacity_pack_summary_fields(row, summary) do
    [
      {"contact_ids_by_direction", "capacity_pack_contact_ids_by_direction"},
      {"selected_contact_ids_by_direction", "capacity_pack_selected_contact_ids_by_direction"},
      {"deferred_contact_ids_by_direction", "capacity_pack_deferred_contact_ids_by_direction"},
      {"required_capacity_fraction_by_direction",
       "capacity_pack_required_capacity_fraction_by_direction"},
      {"selected_required_capacity_fraction_by_direction",
       "capacity_pack_selected_required_capacity_fraction_by_direction"},
      {"deferred_required_capacity_fraction_by_direction",
       "capacity_pack_deferred_required_capacity_fraction_by_direction"}
    ]
    |> Enum.reduce(row, fn {row_field, summary_field}, acc ->
      put_default_if_present(acc, row_field, summary[summary_field])
    end)
  end

  defp put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  defp put_default_if_present(map, field, value) do
    case Map.get(map, field) do
      existing when existing in [nil, ""] -> Map.put(map, field, value)
      _existing -> map
    end
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
