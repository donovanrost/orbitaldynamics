Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactAllocationCapacityPackSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  @plural_prefix "campaign_repair.source_contact_allocation_capacity_pack_summaries[0]"
  @plural_allocation_source @plural_prefix <> ".review_rows"
  @plural_group_source @plural_prefix <> ".reduced_capacity_pack_groups"
  @singular_prefix "campaign_repair.source_contact_allocation_capacity_pack_summary"
  @singular_allocation_source @singular_prefix <> ".review_rows"
  @singular_group_source @singular_prefix <> ".reduced_capacity_pack_groups"

  setup_all do
    source_summary =
      read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_contact_allocation_capacity_pack_summary"],
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
      |> Map.delete("source_contact_allocation_capacity_pack_summaries")
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> rebuild_review_handoffs()

    %{
      repair: repair,
      singular_repair: singular_repair,
      source_summary: source_summary
    }
  end

  test "validates both ordered Repair source capacity-pack-summary handoff surfaces", %{
    repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    allocation_reviews = source_review_rows(repair, @plural_allocation_source)
    allocation_imports = source_import_rows(repair, @plural_allocation_source)
    group_reviews = source_review_rows(repair, @plural_group_source)
    group_imports = source_import_rows(repair, @plural_group_source)

    source_contact_ids = Enum.map(source_summary["review_rows"], & &1["contact_id"])

    assert source_contact_ids == [
             "dl_capacity_primary",
             "dl_capacity_secondary",
             "dl_capacity_overflow"
           ]

    assert Enum.map(allocation_reviews, & &1["contact_id"]) == source_contact_ids
    assert Enum.map(allocation_imports, & &1["contact_id"]) == source_contact_ids
    assert Enum.all?(allocation_reviews, &(row_source(&1) == @plural_allocation_source))
    assert Enum.all?(allocation_imports, &(row_source(&1) == @plural_allocation_source))

    assert [group] = source_summary["reduced_capacity_pack_groups"]
    assert [group_review] = group_reviews
    assert [group_import] = group_imports
    assert row_source(group_review) == @plural_group_source
    assert row_source(group_import) == @plural_group_source
    assert group_review["contention_group_id"] == group["contention_group_id"]
    assert group_import["contention_group_id"] == group["contention_group_id"]

    assert get_in(group_review, ["source_contact_allocation_capacity_pack", "capacity_fraction"]) ==
             group["capacity_fraction"]

    assert get_in(group_import, ["source_contact_allocation_capacity_pack", "capacity_fraction"]) ==
             group["capacity_fraction"]

    assert get_in(group_import, [
             "source_review_row",
             "source_contact_allocation_capacity_pack",
             "capacity_fraction"
           ]) == group["capacity_fraction"]

    assert get_in(group_review, [
             "source_contact_allocation_capacity_pack",
             "capacity_pack_contact_ids_by_direction"
           ]) == %{
             "downlink" => [
               "dl_capacity_overflow",
               "dl_capacity_primary",
               "dl_capacity_secondary"
             ]
           }
  end

  test "validates both singular capacity-pack-summary compatibility fallbacks", %{
    singular_repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    allocation_reviews = source_review_rows(repair, @singular_allocation_source)
    allocation_imports = source_import_rows(repair, @singular_allocation_source)
    group_reviews = source_review_rows(repair, @singular_group_source)
    group_imports = source_import_rows(repair, @singular_group_source)
    contact_ids = Enum.map(source_summary["review_rows"], & &1["contact_id"])

    assert Enum.map(allocation_reviews, & &1["contact_id"]) == contact_ids
    assert Enum.map(allocation_imports, & &1["contact_id"]) == contact_ids
    assert length(group_reviews) == 1
    assert length(group_imports) == 1
    assert Enum.all?(group_reviews, &(row_source(&1) == @singular_group_source))
    assert Enum.all?(group_imports, &(row_source(&1) == @singular_group_source))
  end

  test "keeps additive source capacity-pack-summary handoffs optional", %{
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
            copy_field = summary_copy_field(row)

            row
            |> Map.delete(copy_field)
            |> update_in(["source_review_row"], &Map.delete(&1, copy_field))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source capacity-pack allocation-row handoff drift", %{
    repair: repair
  } do
    review_index = source_review_index(repair, @plural_allocation_source)
    import_index = source_import_index(repair, @plural_allocation_source)
    wrong_source = @plural_allocation_source <> ".legacy"

    review_source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        wrong_source
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_contact_allocation",
          "review_status"
        ],
        "drifted"
      )

    import_nested_source_drift =
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
      )

    import_outer_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_contact_allocation",
          "review_status"
        ],
        "drifted"
      )

    import_nested_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source_contact_allocation",
          "review_status"
        ],
        "drifted"
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_contact_allocation",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       import_nested_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_allocation",
       import_outer_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_allocation",
       import_nested_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects Repair source capacity-pack group handoff drift and eligibility changes", %{
    repair: repair
  } do
    review_index = source_review_index(repair, @plural_group_source)
    import_index = source_import_index(repair, @plural_group_source)
    wrong_source = @plural_group_source <> ".legacy"

    review_source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        wrong_source
      )

    import_source_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        wrong_source
      )

    import_nested_source_drift =
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
      )

    coordinated_copy_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_group_capacity(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_group_capacity(&1, true)
      )

    empty_summary =
      []
      |> OrbitalDynamics.contact_allocation_report([])
      |> OrbitalDynamics.contact_allocation_capacity_pack_summary()

    eligibility_drift =
      repair
      |> Map.put("source_contact_allocation_capacity_pack_summary", empty_summary)
      |> Map.put("source_contact_allocation_capacity_pack_summaries", [empty_summary])

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", import_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       import_nested_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_contact_allocation_capacity_pack",
       coordinated_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_allocation_capacity_pack",
       coordinated_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_allocation_capacity_pack",
       coordinated_copy_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift}
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
    if summary_row?(row), do: Map.delete(row, summary_copy_field(row)), else: row
  end

  defp put_group_capacity(row, nested?) do
    row =
      row
      |> Map.put("capacity_fraction", 0.4)
      |> put_in(["source_contact_allocation_capacity_pack", "capacity_fraction"], 0.4)

    if nested? do
      row
      |> put_in(["source_review_row", "capacity_fraction"], 0.4)
      |> put_in(
        ["source_review_row", "source_contact_allocation_capacity_pack", "capacity_fraction"],
        0.4
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

  defp summary_copy_field(row) do
    if row_source(row) == @plural_group_source,
      do: "source_contact_allocation_capacity_pack",
      else: "source_contact_allocation"
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
