defmodule OrbitalDynamics.Schema.FilterReportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Communications.ContactFilter, ResourceFilter, Schema}

  test "validates standalone contact and resource filter report fixtures" do
    contact_filter_report = read_json!("study_results/contact_filter_report_v1.json")

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(contact_filter_report,
               schema_contract: "contact_filter_report.v1"
             )

    invalid_contact_filter_model =
      Map.put(contact_filter_report, "model", "stale_contact_filter_model")

    assert {:error, contact_filter_model_report} =
             Schema.validate_artifact(invalid_contact_filter_model,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(contact_filter_model_report["errors"], &(&1["path"] == "$.model"))

    assert {:ok, contact_filter_schema} = Schema.json_schema("contact_filter_report.v1")

    assert get_in(contact_filter_schema, ["properties", "model", "const"]) ==
             "thin_ground_network_availability_filter"

    expected_contact_filter_assumptions = contact_filter_report_capability_assumptions()

    for {field, value} <- expected_contact_filter_assumptions do
      assert get_in(contact_filter_schema, [
               "properties",
               "assumptions",
               "properties",
               field,
               "const"
             ]) == value
    end

    assert get_in(contact_filter_schema, ["properties", "model_limits", "items", "enum"]) == [
             "artifact_level_only",
             "externally_supplied_ground_network",
             "no_provider_reservation",
             "no_schedule_mutation",
             "no_link_budget_model"
           ]

    assert get_in(contact_filter_schema, [
             "properties",
             "station_reservation_match_status_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    assert get_in(contact_filter_schema, [
             "properties",
             "invalid_contact_input_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    contact_suppressed_schema =
      get_in(contact_filter_schema, ["properties", "suppressed_candidates", "items"])

    assert get_in(contact_suppressed_schema, ["properties", "capacity_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(contact_suppressed_schema, [
             "properties",
             "station_reservation_match_status",
             "type"
           ]) == "string"

    assert get_in(contact_filter_schema, ["properties", "input_candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(contact_filter_schema, [
             "properties",
             "duplicate_suppressed_candidate_row_count"
           ]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    invalid_contact_filter_limits =
      Map.put(contact_filter_report, "model_limits", ["artifact_level_only"])

    assert {:error, contact_filter_limits_report} =
             Schema.validate_artifact(invalid_contact_filter_limits,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(contact_filter_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_contact_filter_input_count =
      Map.put(contact_filter_report, "input_candidate_count", 1.0)

    assert {:error, contact_filter_input_count_report} =
             Schema.validate_artifact(invalid_contact_filter_input_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             contact_filter_input_count_report["errors"],
             &(&1["path"] == "$.input_candidate_count")
           )

    invalid_contact_filter_optional_count =
      Map.put(contact_filter_report, "duplicate_suppressed_candidate_row_count", -1)

    assert {:error, contact_filter_optional_count_report} =
             Schema.validate_artifact(invalid_contact_filter_optional_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             contact_filter_optional_count_report["errors"],
             &(&1["path"] == "$.duplicate_suppressed_candidate_row_count")
           )

    invalid_contact_filter_match_count =
      put_in(contact_filter_report, ["station_reservation_match_status_counts", "overlap"], 99)

    assert {:error, contact_filter_match_count_report} =
             Schema.validate_artifact(invalid_contact_filter_match_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             contact_filter_match_count_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    invalid_contact_filter_duplicate_count =
      Map.put(contact_filter_report, "duplicate_suppressed_candidate_row_count", 99)

    assert {:error, contact_filter_duplicate_count_report} =
             Schema.validate_artifact(invalid_contact_filter_duplicate_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             contact_filter_duplicate_count_report["errors"],
             &(&1["path"] == "$.duplicate_suppressed_candidate_row_count")
           )

    invalid_contact_capacity_fraction =
      put_in(
        contact_filter_report,
        ["suppressed_candidates", Access.at(0), "capacity_fraction"],
        1.5
      )

    assert {:error, contact_capacity_fraction_report} =
             Schema.validate_artifact(invalid_contact_capacity_fraction,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             contact_capacity_fraction_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].capacity_fraction")
           )

    invalid_contact_match_status =
      put_in(
        contact_filter_report,
        ["suppressed_candidates", Access.at(1), "station_reservation_match_status"],
        7
      )

    assert {:error, contact_match_status_report} =
             Schema.validate_artifact(invalid_contact_match_status,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             contact_match_status_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[1].station_reservation_match_status")
           )

    resource_filter_report = read_json!("study_results/resource_filter_report_v1.json")

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(resource_filter_report,
               schema_contract: "resource_filter_report.v1"
             )

    assert {:ok, resource_filter_schema} = Schema.json_schema("resource_filter_report.v1")

    expected_resource_filter_assumptions = resource_filter_report_capability_assumptions()

    for {field, value} <- expected_resource_filter_assumptions do
      assert get_in(resource_filter_schema, [
               "properties",
               "assumptions",
               "properties",
               field,
               "const"
             ]) == value
    end

    resource_suppressed_schema =
      get_in(resource_filter_schema, ["properties", "suppressed_candidates", "items"])

    assert get_in(resource_suppressed_schema, [
             "properties",
             "resource_blocking_dimension",
             "type"
           ]) == "string"

    assert get_in(resource_suppressed_schema, [
             "properties",
             "resource_trust_boundary_status",
             "type"
           ]) == "string"

    invalid_resource_blocking_dimension =
      put_in(
        resource_filter_report,
        ["suppressed_candidates", Access.at(0), "resource_blocking_dimension"],
        ["storage"]
      )

    assert {:error, resource_blocking_dimension_report} =
             Schema.validate_artifact(invalid_resource_blocking_dimension,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             resource_blocking_dimension_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[0].resource_blocking_dimension")
           )

    invalid_resource_trust_boundary_status =
      put_in(
        resource_filter_report,
        ["suppressed_candidates", Access.at(1), "resource_trust_boundary_status"],
        7
      )

    assert {:error, resource_trust_boundary_status_report} =
             Schema.validate_artifact(invalid_resource_trust_boundary_status,
               schema_contract: "resource_filter_report.v1"
             )

    assert Enum.any?(
             resource_trust_boundary_status_report["errors"],
             &(&1["path"] == "$.suppressed_candidates[1].resource_trust_boundary_status")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp contact_filter_report_capability_assumptions do
    capabilities = ContactFilter.capabilities()

    %{
      "suppressed_directions" => capabilities.suppressed_directions,
      "suppression_reasons" => capabilities.suppression_reasons,
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "station_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.station_capacity_value_paths),
      "contact_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.contact_capacity_value_paths),
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp resource_filter_report_capability_assumptions do
    capabilities = ResourceFilter.capabilities()

    %{
      "resource_filter_policy_fields" => capabilities.resource_filter_policy_fields,
      "resource_availability_aliases" => capabilities.resource_availability_aliases,
      "resource_degraded_aliases" => capabilities.resource_degraded_aliases,
      "resource_margin_aliases" => capabilities.resource_margin_aliases,
      "resource_power_margin_source_aliases" => capabilities.resource_power_margin_source_aliases,
      "resource_availability_true_tokens" => capabilities.resource_availability_true_tokens,
      "resource_availability_false_tokens" => capabilities.resource_availability_false_tokens,
      "provider_direction_aliases" => capabilities.provider_direction_aliases,
      "station_calendar_direction_aliases" => capabilities.station_calendar_direction_aliases,
      "provider_result_map_value_keys" => capabilities.provider_result_map_value_keys,
      "candidate_stable_identity_fields" => capabilities.candidate_stable_identity_fields,
      "station_calendar_id_list_fields" => capabilities.station_calendar_id_list_fields,
      "suppression_reasons" => capabilities.suppression_reasons,
      "row_review_statuses" => capabilities.row_review_statuses
    }
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end
end
