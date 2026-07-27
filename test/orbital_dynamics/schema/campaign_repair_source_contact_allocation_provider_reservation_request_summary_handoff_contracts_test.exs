Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactAllocationProviderReservationRequestSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  @plural_prefix "campaign_repair.source_contact_allocation_provider_reservation_request_summaries[0]"
  @plural_source @plural_prefix <> ".provider_reservation_request_rows"
  @singular_prefix "campaign_repair.source_contact_allocation_provider_reservation_request_summary"
  @singular_source @singular_prefix <> ".provider_reservation_request_rows"

  setup_all do
    source_summary =
      read_json!("study_results/contact_allocation_provider_reservation_request_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        [
          "candidate_refresh",
          "source_contact_allocation_provider_reservation_request_summary"
        ],
        [source_summary]
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    singular_repair =
      repair
      |> Map.delete("source_contact_allocation_provider_reservation_request_summaries")
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> rebuild_review_handoffs()

    %{
      repair: repair,
      singular_repair: singular_repair
    }
  end

  test "validates ordered Repair source provider-reservation-request handoffs", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    reviews = source_review_rows(repair, @plural_source)
    imports = source_import_rows(repair, @plural_source)

    assert Enum.map(reviews, & &1["contact_id"]) == [
             "dl_reserved_owner",
             "dl_review_overlap"
           ]

    assert Enum.map(imports, & &1["contact_id"]) == [
             "dl_reserved_owner",
             "dl_review_overlap"
           ]

    assert Enum.map(reviews, & &1["provider_reservation_request_status"]) == [
             "request_ready",
             "review_required"
           ]

    assert Enum.map(imports, & &1["provider_reservation_request_status"]) == [
             "request_ready",
             "review_required"
           ]

    assert Enum.map(reviews, & &1["action"]) == [
             "review_provider_reservation_request",
             "review_contact_allocation"
           ]

    assert Enum.map(imports, & &1["import_action"]) == [
             "review_provider_reservation_request",
             "review_contact_allocation"
           ]

    assert Enum.all?(reviews, &(row_source(&1) == @plural_source))
    assert Enum.all?(imports, &(row_source(&1) == @plural_source))

    assert get_in(List.first(reviews), [
             "source_contact_allocation",
             "provider_reservation_request_status"
           ]) == "request_ready"

    assert get_in(List.first(imports), [
             "source_review_row",
             "source_contact_allocation",
             "provider_reservation_request_status"
           ]) == "request_ready"
  end

  test "validates the singular provider-reservation-request compatibility fallback", %{
    singular_repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    reviews = source_review_rows(repair, @singular_source)
    imports = source_import_rows(repair, @singular_source)

    assert Enum.map(reviews, & &1["contact_id"]) == [
             "dl_reserved_owner",
             "dl_review_overlap"
           ]

    assert Enum.map(imports, & &1["contact_id"]) == [
             "dl_reserved_owner",
             "dl_review_overlap"
           ]

    assert Enum.all?(reviews, &(row_source(&1) == @singular_source))
    assert Enum.all?(imports, &(row_source(&1) == @singular_source))
  end

  test "keeps additive provider-reservation-request handoffs optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_summary_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if summary_row?(row) do
            row
            |> Map.delete("source_contact_allocation")
            |> update_in(
              ["source_review_row"],
              &Map.delete(&1, "source_contact_allocation")
            )
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects provider-reservation-request identity and copy drift", %{
    repair: repair
  } do
    review_index = source_review_index(repair, @plural_source)
    import_index = source_import_index(repair, @plural_source)
    wrong_source = @plural_source <> ".legacy"

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source",
       put_in(
         repair,
         ["operator_review_package", "rows", Access.at(review_index), "source"],
         wrong_source
       )},
      {"$.operator_review_package.rows[#{review_index}].source_contact_allocation",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_contact_allocation",
           "provider_reservation_request_status"
         ],
         "review_required"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source",
       put_in(
         repair,
         ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
         wrong_source
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source"
         ],
         wrong_source
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_allocation",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_contact_allocation",
           "provider_reservation_request_status"
         ],
         "review_required"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_allocation",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source_contact_allocation",
           "provider_reservation_request_status"
         ],
         "review_required"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated provider request-status drift and missing handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair, @plural_source)
    import_index = source_import_index(repair, @plural_source)

    coordinated_status_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_provider_status(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_provider_status(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_contact_allocation",
       coordinated_status_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_allocation",
       coordinated_status_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_allocation",
       coordinated_status_drift},
      {"$.operator_review_package.rows", missing_review},
      {"$.cadence_import_manifest.rows", missing_import}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp rebuild_review_handoffs(repair) do
    review_package = OperatorReview.from_repair_artifact(repair)
    repair = Map.put(repair, "operator_review_package", review_package)
    Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))
  end

  defp drop_summary_copy(row) do
    if summary_row?(row), do: Map.delete(row, "source_contact_allocation"), else: row
  end

  defp put_provider_status(row, nested?) do
    row =
      row
      |> Map.put("provider_reservation_request_status", "review_required")
      |> put_in(
        ["source_contact_allocation", "provider_reservation_request_status"],
        "review_required"
      )

    if nested? do
      row
      |> put_in(
        ["source_review_row", "provider_reservation_request_status"],
        "review_required"
      )
      |> put_in(
        [
          "source_review_row",
          "source_contact_allocation",
          "provider_reservation_request_status"
        ],
        "review_required"
      )
    else
      row
    end
  end

  defp source_review_rows(repair, source) do
    Enum.filter(
      get_in(repair, ["operator_review_package", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_import_rows(repair, source) do
    Enum.filter(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_review_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_import_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp summary_row?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @plural_prefix)
      _source -> false
    end
  end

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
