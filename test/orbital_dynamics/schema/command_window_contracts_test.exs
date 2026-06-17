defmodule OrbitalDynamics.Schema.CommandWindowContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates and exports command window report scalar counters" do
    report = read_json!("study_results/command_window_report_v1.json")

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    stale_model = Map.put(report, "model", "stale_command_window_report")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    float_window_count = Map.put(report, "window_count", 1.0)

    assert {:error, float_window_count_report} =
             Schema.validate_artifact(float_window_count)

    assert Enum.any?(
             float_window_count_report["errors"],
             &(&1["path"] == "$.window_count")
           )

    negative_lineage_count = Map.put(report, "source_window_lineage_count", -1)

    assert {:error, negative_lineage_count_report} =
             Schema.validate_artifact(negative_lineage_count)

    assert Enum.any?(
             negative_lineage_count_report["errors"],
             &(&1["path"] == "$.source_window_lineage_count")
           )

    assert {:ok, schema} = Schema.json_schema("command_window_report.v1")

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_command_window_report"

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "window_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "health_check_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "source_window_lineage_count"]) ==
             %{"type" => "integer", "minimum" => 0}
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
