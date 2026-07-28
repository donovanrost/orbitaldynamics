defmodule OrbitalDynamics.Schema.CampaignRepairOperationalReadinessHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_readiness_source "campaign_repair.source_operational_readiness_report"
  @repair_readiness_gate_source "#{@repair_readiness_source}.gates"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair operational-readiness review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive operational-readiness handoff packages and copies optional", %{
    readiness_repair: repair
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_indexes = readiness_review_indexes(repair)
    cadence_indexes = readiness_import_indexes(repair)

    older =
      repair
      |> drop_review_copies(review_indexes)
      |> drop_import_copies(cadence_indexes)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair operational-readiness review handoff drift", %{
    readiness_repair: repair
  } do
    [report_review_index, gate_review_index] = readiness_review_indexes(repair)
    [report_import_index, gate_import_index] = readiness_import_indexes(repair)

    readiness_pressure = get_in(repair, ["score_terms", "operational_readiness_pressure_penalty"])

    stale_handoffs =
      repair
      |> Map.delete("source_operational_readiness_report")
      |> put_in(["score_terms", "operational_readiness_pressure_penalty"], 0.0)
      |> Map.update!("score", &(&1 - readiness_pressure))
      |> Map.delete("score_term_report")
      |> Map.delete("objective_tradeoff_report")

    invalid_cases = [
      {"$.operator_review_package.rows",
       put_in(
         repair,
         ["operator_review_package", "rows", Access.at(report_review_index), "source"],
         "campaign_repair.operational_readiness_report"
       )},
      {"$.cadence_import_manifest.rows",
       put_in(
         repair,
         ["cadence_import_manifest", "rows", Access.at(gate_import_index), "source"],
         "campaign_repair.operational_readiness_report.gates"
       )},
      {"$.operator_review_package.rows[#{report_review_index}].source_operational_readiness_report",
       update_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(report_review_index),
           "source_operational_readiness_report"
         ],
         &Map.put(&1, "gate_count", 99)
       )},
      {"$.operator_review_package.rows[#{gate_review_index}].source_operational_readiness_gate",
       update_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(gate_review_index),
           "source_operational_readiness_gate"
         ],
         &Map.put(&1, "reason", "drifted")
       )},
      {"$.cadence_import_manifest.rows[#{report_import_index}].source_operational_readiness_report",
       update_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(report_import_index),
           "source_operational_readiness_report"
         ],
         &Map.put(&1, "gate_count", 99)
       )},
      {"$.cadence_import_manifest.rows[#{gate_import_index}].source_review_row.source_operational_readiness_gate",
       update_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(gate_import_index),
           "source_review_row",
           "source_operational_readiness_gate"
         ],
         &Map.put(&1, "reason", "drifted")
       )},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp readiness_review_indexes(repair) do
    repair
    |> get_in(["operator_review_package", "rows"])
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} ->
      row["review_type"] == "operational_readiness_review" and
        row["source"] in [@repair_readiness_source, @repair_readiness_gate_source]
    end)
    |> Enum.map(&elem(&1, 1))
  end

  defp readiness_import_indexes(repair) do
    repair
    |> get_in(["cadence_import_manifest", "rows"])
    |> Enum.with_index()
    |> Enum.filter(fn {row, _index} ->
      row["source_review_type"] == "operational_readiness_review" and
        row["source"] in [@repair_readiness_source, @repair_readiness_gate_source]
    end)
    |> Enum.map(&elem(&1, 1))
  end

  defp drop_review_copies(repair, indexes) do
    Enum.reduce(indexes, repair, fn index, acc ->
      update_in(acc, ["operator_review_package", "rows", Access.at(index)], fn row ->
        Map.drop(row, [
          "source_operational_readiness_report",
          "source_operational_readiness_gate"
        ])
      end)
    end)
  end

  defp drop_import_copies(repair, indexes) do
    Enum.reduce(indexes, repair, fn index, acc ->
      update_in(acc, ["cadence_import_manifest", "rows", Access.at(index)], fn row ->
        row
        |> Map.drop([
          "source_operational_readiness_report",
          "source_operational_readiness_gate"
        ])
        |> update_in(["source_review_row"], fn source_review_row ->
          Map.drop(source_review_row, [
            "source_operational_readiness_report",
            "source_operational_readiness_gate"
          ])
        end)
      end)
    end)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
