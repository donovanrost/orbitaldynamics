Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactContentionReportHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @invalid_source "campaign_repair.source_contact_contention_report.invalid_contact_inputs"
  @group_source "campaign_repair.source_contact_contention_report.conflict_groups"

  setup_all do
    source_report = source_report()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_contact_contention_report"],
        source_report
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_report: source_report}
  end

  test "validates both source contention-report handoff surfaces in producer order", %{
    repair: repair,
    source_report: source_report
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert [invalid_review] = source_review_rows(repair, @invalid_source)
    assert [invalid_import] = source_import_rows(repair, @invalid_source)
    group_reviews = source_review_rows(repair, @group_source)
    group_imports = source_import_rows(repair, @group_source)

    assert invalid_review["subject_id"] == "invalid_contact:malformed_contact"
    assert invalid_import["subject_id"] == "invalid_contact:malformed_contact"

    assert invalid_review["source_invalid_contact_input"] ==
             List.first(source_report["invalid_contact_inputs"])

    assert get_in(invalid_import, ["source_review_row", "source_invalid_contact_input"]) ==
             List.first(source_report["invalid_contact_inputs"])

    assert Enum.map(group_reviews, & &1["subject_id"]) == [
             "station:equator_prime:contention:1",
             "spacecraft:sat_1:contention:1"
           ]

    assert Enum.map(group_imports, & &1["subject_id"]) == [
             "station:equator_prime:contention:1",
             "spacecraft:sat_1:contention:1"
           ]

    assert Enum.map(group_reviews, & &1["source_contention_group"]) ==
             source_report["conflict_groups"]

    assert Enum.map(group_imports, & &1["source_contention_group"]) ==
             source_report["conflict_groups"]
  end

  test "keeps additive source contention-report handoffs and copies optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_surface_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if surface_row?(row) do
            row
            |> drop_surface_copy()
            |> update_in(["source_review_row"], &drop_surface_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects both source contention-report surface identities", %{
    repair: repair
  } do
    invalid_review_index = source_review_index(repair, @invalid_source)
    invalid_import_index = source_import_index(repair, @invalid_source)
    group_review_index = source_review_index(repair, @group_source)
    group_import_index = source_import_index(repair, @group_source)

    invalid_cases =
      identity_cases(
        repair,
        invalid_review_index,
        invalid_import_index,
        @invalid_source <> ".legacy"
      ) ++
        identity_cases(
          repair,
          group_review_index,
          group_import_index,
          @group_source <> ".legacy"
        )

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects both source contention-report surface-copy drifts", %{
    repair: repair
  } do
    invalid_review_index = source_review_index(repair, @invalid_source)
    invalid_import_index = source_import_index(repair, @invalid_source)
    group_review_index = source_review_index(repair, @group_source)
    group_import_index = source_import_index(repair, @group_source)

    invalid_cases = [
      {"$.operator_review_package.rows[#{invalid_review_index}].source_invalid_contact_input",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(invalid_review_index),
           "source_invalid_contact_input",
           "invalid_contact_input_reason"
         ],
         "drifted_invalid_shape"
       )},
      {"$.cadence_import_manifest.rows[#{invalid_import_index}].source_invalid_contact_input",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(invalid_import_index),
           "source_invalid_contact_input",
           "invalid_contact_input_reason"
         ],
         "drifted_invalid_shape"
       )},
      {"$.cadence_import_manifest.rows[#{invalid_import_index}].source_review_row.source_invalid_contact_input",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(invalid_import_index),
           "source_review_row",
           "source_invalid_contact_input",
           "invalid_contact_input_reason"
         ],
         "drifted_invalid_shape"
       )},
      {"$.operator_review_package.rows[#{group_review_index}].source_contention_group",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(group_review_index),
           "source_contention_group",
           "contact_ids"
         ],
         ["dl_2", "dl_1"]
       )},
      {"$.cadence_import_manifest.rows[#{group_import_index}].source_contention_group",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(group_import_index),
           "source_contention_group",
           "contact_ids"
         ],
         ["dl_2", "dl_1"]
       )},
      {"$.cadence_import_manifest.rows[#{group_import_index}].source_review_row.source_contention_group",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(group_import_index),
           "source_review_row",
           "source_contention_group",
           "contact_ids"
         ],
         ["dl_2", "dl_1"]
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated surface drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    invalid_review_index = source_review_index(repair, @invalid_source)
    invalid_import_index = source_import_index(repair, @invalid_source)
    group_review_index = source_review_index(repair, @group_source)
    group_import_index = source_import_index(repair, @group_source)

    coordinated_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(invalid_review_index)],
        &put_invalid_reason(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(invalid_import_index)],
        &put_invalid_reason(&1, true)
      )
      |> update_in(
        ["operator_review_package", "rows", Access.at(group_review_index)],
        &put_group_contacts(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(group_import_index)],
        &put_group_contacts(&1, true)
      )

    missing_invalid_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, invalid_review_index)
      end)

    missing_group_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, group_import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_contact_contention_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{invalid_review_index}].source_invalid_contact_input",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{invalid_import_index}].source_review_row.source_invalid_contact_input",
       coordinated_drift},
      {"$.operator_review_package.rows[#{group_review_index}].source_contention_group",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{group_import_index}].source_review_row.source_contention_group",
       coordinated_drift},
      {"$.operator_review_package.rows", missing_invalid_review},
      {"$.cadence_import_manifest.rows", missing_group_import},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp identity_cases(repair, review_index, import_index, wrong_source) do
    [
      {"$.operator_review_package.rows[#{review_index}].source",
       put_in(
         repair,
         ["operator_review_package", "rows", Access.at(review_index), "source"],
         wrong_source
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
       )}
    ]
  end

  defp drop_surface_copy(row) do
    case row_source(row) do
      @invalid_source -> Map.delete(row, "source_invalid_contact_input")
      @group_source -> Map.delete(row, "source_contention_group")
      _source -> row
    end
  end

  defp put_invalid_reason(row, nested?) do
    row =
      row
      |> Map.put("invalid_contact_input_reason", "drifted_invalid_shape")
      |> put_in(
        ["source_invalid_contact_input", "invalid_contact_input_reason"],
        "drifted_invalid_shape"
      )

    if nested? do
      row
      |> put_in(
        ["source_review_row", "invalid_contact_input_reason"],
        "drifted_invalid_shape"
      )
      |> put_in(
        [
          "source_review_row",
          "source_invalid_contact_input",
          "invalid_contact_input_reason"
        ],
        "drifted_invalid_shape"
      )
    else
      row
    end
  end

  defp put_group_contacts(row, nested?) do
    row =
      row
      |> Map.put("contact_ids", ["dl_2", "dl_1"])
      |> put_in(["source_contention_group", "contact_ids"], ["dl_2", "dl_1"])

    if nested? do
      row
      |> put_in(["source_review_row", "contact_ids"], ["dl_2", "dl_1"])
      |> put_in(
        ["source_review_row", "source_contention_group", "contact_ids"],
        ["dl_2", "dl_1"]
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

  defp surface_row?(row), do: row_source(row) in [@invalid_source, @group_source]

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp source_report do
    invalid_input = %{
      "id" => "invalid_contact:malformed_contact",
      "contact_id" => "malformed_contact",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 100.0,
      "ends_at_s" => 180.0,
      "direction" => "downlink",
      "required_operator_action" => "review_invalid_contact_contention_input",
      "approval_status" => "operator_review_required",
      "operator_action_reason" => "invalid_contact_shape",
      "invalid_contact_input" => true,
      "invalid_contact_input_reason" => "invalid_contact_shape"
    }

    "study_results/contact_contention_report_v1.json"
    |> read_json!()
    |> Map.put("input_contact_count", 5)
    |> Map.put("invalid_contact_input_count", 1)
    |> Map.put("invalid_contact_input_ids", ["malformed_contact"])
    |> Map.put("invalid_contact_inputs", [invalid_input])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
