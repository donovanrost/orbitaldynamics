defmodule OrbitalDynamics.Schema.LintStrategyBranchContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone lint report and strategy branch fixtures" do
    request_lint = read_json!("study_results/campaign_request_lint_v1.json")
    manifest_lint = read_json!("study_results/study_manifest_lint_v1.json")
    strategy_branch = read_json!("study_results/strategy_branch_v1.json")

    assert {:ok, %{"schema_contract" => "campaign_request_lint.v1"}} =
             Schema.validate_artifact(request_lint)

    assert {:ok, %{"schema_contract" => "study_manifest_lint.v1"}} =
             Schema.validate_artifact(manifest_lint)

    assert {:ok, %{"schema_contract" => "strategy_branch.v1"}} =
             Schema.validate_artifact(strategy_branch)

    invalid_lint = Map.put(request_lint, "error_count", 3)

    assert {:error, lint_report} = Schema.validate_artifact(invalid_lint)
    assert Enum.any?(lint_report["errors"], &(&1["path"] == "$.error_count"))

    non_integer_lint = Map.put(request_lint, "error_count", 0.0)

    assert {:error, non_integer_lint_report} = Schema.validate_artifact(non_integer_lint)
    assert Enum.any?(non_integer_lint_report["errors"], &(&1["path"] == "$.error_count"))

    invalid_manifest_lint = Map.put(manifest_lint, "warning_count", 1)

    assert {:error, manifest_lint_report} = Schema.validate_artifact(invalid_manifest_lint)
    assert Enum.any?(manifest_lint_report["errors"], &(&1["path"] == "$.warning_count"))

    invalid_branch = Map.put(strategy_branch, "probability", 1.5)

    assert {:error, branch_report} = Schema.validate_artifact(invalid_branch)
    assert Enum.any?(branch_report["errors"], &(&1["path"] == "$.probability"))

    invalid_score_terms =
      put_in(strategy_branch, ["score_terms", "branch_score"], "not_numeric")

    assert {:error, branch_score_report} = Schema.validate_artifact(invalid_score_terms)
    assert Enum.any?(branch_score_report["errors"], &(&1["path"] == "$.score_terms.branch_score"))

    invalid_event =
      put_in(strategy_branch, ["events"], [
        %{"type" => "contact_success_feedback", "contact_success_factor" => 1.5}
      ])

    assert {:error, branch_event_report} = Schema.validate_artifact(invalid_event)

    assert Enum.any?(
             branch_event_report["errors"],
             &(&1["path"] == "$.events[0].contact_success_factor")
           )

    invalid_downlink_identity_event =
      put_in(strategy_branch, ["events"], [
        %{
          "type" => "downlink_completion_gap",
          "collection_ids" => ["collection_alpha", "bad collection"],
          "product_ids" => ["product_alpha"],
          "payload_ids" => ["payload_a"],
          "instrument_ids" => ["instrument_a"]
        }
      ])

    assert {:error, downlink_identity_event_report} =
             Schema.validate_artifact(invalid_downlink_identity_event)

    assert Enum.any?(
             downlink_identity_event_report["errors"],
             &(&1["path"] == "$.events[0].collection_ids[1]")
           )

    invalid_station_event =
      put_in(strategy_branch, ["events"], [
        %{
          "type" => "reduced_downlink_capacity",
          "ground_station_id" => "equator_prime",
          "station_calendar_entry_id" => "dsn_capacity",
          "station_calendar_provider_id" => "ground_partner",
          "station_calendar_provider_entry_id" => "dsn_capacity",
          "station_calendar_overlap_entry_ids" => ["dsn_capacity"],
          "station_calendar_reservation_ids" => ["reservation_42"],
          "station_calendar_directions" => ["downlink"],
          "station_calendar_reserved_by" => ["ops_team_b"],
          "station_calendar_reservation_statuses" => ["confirmed"],
          "station_calendar_trust_boundary_status" => "declared",
          "station_calendar_overlap_count" => 1.5,
          "capacity_fraction" => 1.25
        }
      ])

    assert {:error, station_event_report} = Schema.validate_artifact(invalid_station_event)

    assert Enum.any?(
             station_event_report["errors"],
             &(&1["path"] == "$.events[0].station_calendar_overlap_count")
           )

    assert Enum.any?(
             station_event_report["errors"],
             &(&1["path"] == "$.events[0].capacity_fraction")
           )

    invalid_capacity_pack_event =
      put_in(strategy_branch, ["events"], [
        %{
          "type" => "downlink_completion_gap",
          "capacity_pack_group_id" => "station:equator_prime:pack:review",
          "capacity_pack_capacity_fraction" => 0.5,
          "capacity_pack_used_fraction" => 1.2,
          "capacity_pack_unused_fraction" => -0.2,
          "required_capacity_fraction" => 1.1,
          "required_capacity_fraction_source" => "contact_required_capacity_fraction"
        }
      ])

    assert {:error, capacity_pack_event_report} =
             Schema.validate_artifact(invalid_capacity_pack_event)

    assert Enum.any?(
             capacity_pack_event_report["errors"],
             &(&1["path"] == "$.events[0].capacity_pack_used_fraction")
           )

    assert Enum.any?(
             capacity_pack_event_report["errors"],
             &(&1["path"] == "$.events[0].capacity_pack_unused_fraction")
           )

    assert Enum.any?(
             capacity_pack_event_report["errors"],
             &(&1["path"] == "$.events[0].required_capacity_fraction")
           )

    invalid_provenance_event =
      put_in(strategy_branch, ["events"], [
        %{
          "type" => "contact_success_feedback",
          "trust_boundary" => ["operator_supplied"],
          "provenance" => "opaque",
          "feedback_source" => 42,
          "feedback_scope" => %{"scope" => "contact"},
          "feedback_sample_weight" => -1.0,
          "sample_weight" => "many",
          "confidence_weight" => "high",
          "feedback_sample_weight_source" => ["operator_sample_size"],
          "sample_weight_source" => 2,
          "confidence_weight_source" => false
        }
      ])

    assert {:error, provenance_event_report} = Schema.validate_artifact(invalid_provenance_event)

    for path <- [
          "$.events[0].trust_boundary",
          "$.events[0].provenance",
          "$.events[0].feedback_source",
          "$.events[0].feedback_scope",
          "$.events[0].feedback_sample_weight",
          "$.events[0].sample_weight",
          "$.events[0].confidence_weight",
          "$.events[0].feedback_sample_weight_source",
          "$.events[0].sample_weight_source",
          "$.events[0].confidence_weight_source"
        ] do
      assert Enum.any?(provenance_event_report["errors"], &(&1["path"] == path))
    end

    assert {:ok, branch_schema} = Schema.json_schema("strategy_branch.v1")

    event_schema = get_in(branch_schema, ["properties", "events", "items"])

    assert event_schema["required"] == ["type"]

    assert get_in(event_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, ["properties", "source_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, ["properties", "collection_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, ["properties", "payload_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, ["properties", "instrument_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, ["properties", "required_downlink_mb", "minimum"]) == 0.0
    assert get_in(event_schema, ["properties", "max_latency_s", "minimum"]) == 0.0
    assert get_in(event_schema, ["properties", "contact_success_factor", "maximum"]) == 1.0
    assert get_in(event_schema, ["properties", "capacity_fraction", "maximum"]) == 1.0
    assert get_in(event_schema, ["properties", "feedback_weight", "minimum"]) == 0.0
    assert get_in(event_schema, ["properties", "feedback_sample_weight", "minimum"]) == 0.0
    assert get_in(event_schema, ["properties", "sample_weight", "minimum"]) == 0.0
    assert get_in(event_schema, ["properties", "confidence_weight", "minimum"]) == 0.0
    assert get_in(event_schema, ["properties", "feedback_weight_source", "type"]) == "string"

    assert get_in(event_schema, ["properties", "feedback_sample_weight_source", "type"]) ==
             "string"

    assert get_in(event_schema, ["properties", "sample_weight_source", "type"]) == "string"
    assert get_in(event_schema, ["properties", "confidence_weight_source", "type"]) == "string"
    assert get_in(event_schema, ["properties", "feedback_source", "type"]) == "string"
    assert get_in(event_schema, ["properties", "feedback_scope", "type"]) == "string"
    assert get_in(event_schema, ["properties", "trust_boundary", "type"]) == "string"
    assert get_in(event_schema, ["properties", "provenance", "type"]) == "object"

    assert get_in(event_schema, ["properties", "capacity_pack_group_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, ["properties", "capacity_pack_used_fraction", "maximum"]) == 1.0
    assert get_in(event_schema, ["properties", "required_capacity_fraction", "maximum"]) == 1.0

    assert get_in(event_schema, ["properties", "required_capacity_fraction_source", "type"]) ==
             "string"

    assert get_in(event_schema, ["properties", "station_calendar_entry_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, [
             "properties",
             "station_calendar_overlap_entry_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(event_schema, [
             "properties",
             "station_calendar_trust_boundary_status",
             "enum"
           ]) == ["declared", "missing"]

    assert get_in(event_schema, [
             "properties",
             "score_terms",
             "additionalProperties",
             "type"
           ]) == "number"

    assert get_in(branch_schema, [
             "properties",
             "score_terms",
             "additionalProperties",
             "type"
           ]) == "number"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
