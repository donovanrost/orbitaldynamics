defmodule Mix.Tasks.OrbitalDynamics.Manifest.ReferenceTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Study.Manifest

  test "prints a text manifest field reference" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.manifest.reference") end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.manifest.reference", [])
      end)

    assert output =~ "OrbitalDynamics manifest field reference"
    assert output =~ "schema: study_manifest.v1"
    assert output =~ "required: schema_version,study_id,outputs"
    assert output =~ "lint error codes:"
    assert output =~ "invalid_run_option"
    assert output =~ "$.candidate_refresh object optional"
    assert output =~ "requiredAnyOf=accepted_planning_state|orbit_data"

    assert output =~
             "$.candidate_refresh.accepted_planning_state object optional schemaContract=accepted_planning_state.v1"

    assert output =~
             "$.candidate_refresh.accepted_planning_state.spacecraft_states.[] object optional schemaContract=spacecraft_state_estimate.v1 trustBoundary=trust_boundary|provenance.trust_boundary"

    assert output =~ "$.candidate_refresh.orbit_data object optional"
    assert output =~ "$.candidate_refresh.remaining_horizon object required"
    assert output =~ "requiredChildren=output_step_s"
    assert output =~ "$.study_id string required stableIdPattern=^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
    assert output =~ "stable ID pattern: ^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert output =~
             "$.candidate_refresh.operational_feedback.downlink_demand_mb object optional additionalProperties=number"

    assert output =~ "supported propagators:"
  end

  test "prints a JSON manifest field reference" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.manifest.reference") end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.manifest.reference", ["--format", "json"])
      end)

    assert %{
             "schema_contract" => "study_manifest.v1",
             "reference_mode" => "study_manifest_schema_field_reference",
             "compatibility_policy_version" => compatibility_policy_version,
             "identity_policy_version" => identity_policy_version,
             "identity_policy" => identity_policy,
             "field_count" => field_count,
             "activation_sections" => activation_sections,
             "supported" => %{
               "lint_error_codes" => lint_error_codes,
               "outputs" => supported_outputs
             },
             "fields" => fields
           } = output |> String.trim() |> :json.decode()

    assert compatibility_policy_version == Schema.compatibility_policy()["policy_version"]
    assert identity_policy_version == Schema.identity_policy()["policy_version"]
    assert identity_policy["stable_id_pattern"] == Schema.identity_policy()["stable_id_pattern"]

    assert "source_record_order_must_not_change_generated_identity" in identity_policy[
             "semantic_invariants"
           ]

    assert Enum.any?(
             identity_policy["generated_id_scopes"],
             &(&1["scope"] == "candidate_refresh.v1.candidate_activities" and
                 "result_event_type" in &1["ordering"])
           )

    assert field_count > 50
    assert "candidate_refresh" in activation_sections
    assert "invalid_run_option" in lint_error_codes
    assert "missing_run_option" in lint_error_codes
    assert "target_visibility" in supported_outputs

    assert Enum.any?(
             fields,
             &(&1["path"] == "$.candidate_refresh.orbit_data.state_estimates.[]" and
                 &1["parent_path"] == "$.candidate_refresh.orbit_data.state_estimates" and
                 &1["section"] == "candidate_refresh" and
                 &1["array_item"] == true and
                 &1["type"] == "object")
           )

    assert Enum.any?(
             fields,
             &(&1["path"] == "$.candidate_refresh.operational_feedback.downlink_demand_mb" and
                 &1["parent_path"] == "$.candidate_refresh.operational_feedback" and
                 &1["section"] == "candidate_refresh" and
                 &1["array_item"] == false and
                 &1["type"] == "object")
           )

    assert Enum.find(fields, &(&1["path"] == "$.candidate_refresh"))[
             "required_alternatives"
           ] == [
             ["accepted_planning_state"],
             ["orbit_data"],
             ["mission_state"]
           ]

    assert %{
             "schema_contract_ref" => "accepted_planning_state.v1",
             "nested_contracts" => nested_contracts
           } =
             Enum.find(fields, &(&1["path"] == "$.candidate_refresh.accepted_planning_state"))

    assert "spacecraft_state_estimate.v1" in nested_contracts
    assert "maneuver_execution_delta.v1" in nested_contracts

    assert Enum.find(
             fields,
             &(&1["path"] == "$.candidate_refresh.accepted_planning_state.spacecraft_states.[]")
           )["schema_contract_ref"] == "spacecraft_state_estimate.v1"

    assert Enum.find(
             fields,
             &(&1["path"] == "$.candidate_refresh.accepted_planning_state.spacecraft_states.[]")
           )["trust_boundary_sources"] == ["trust_boundary", "provenance.trust_boundary"]

    assert Enum.find(
             fields,
             &(&1["path"] == "$.candidate_refresh.orbit_data.state_estimates.[]")
           )["required_alternatives"] == [
             ["epoch"],
             ["seconds_since_j2000"],
             ["state_vector"],
             ["position_km", "velocity_km_s"]
           ]

    assert Enum.find(
             fields,
             &(&1["path"] == "$.candidate_refresh.operational_feedback.downlink_demand_mb")
           )["additional_properties_type"] == "number"

    assert Enum.find(fields, &(&1["path"] == "$.study_id"))["stable_id_pattern"] ==
             Schema.identity_policy()["stable_id_pattern"]

    assert Enum.find(
             fields,
             &(&1["path"] == "$.mission_plans.[].activities.[].dependencies.[]")
           )["stable_id_pattern"] == Schema.identity_policy()["stable_id_pattern"]

    assert Enum.find(
             fields,
             &(&1["path"] == "$.mission_plans.[].activities.[].activity_type")
           )["enum"] ==
             Enum.map(
               OrbitalDynamics.MissionPlan.Activity.capabilities().activity_types,
               &to_string/1
             )
             |> Enum.sort()

    assert Enum.find(fields, &(&1["path"] == "$.mission_plans.[].activities.[]"))[
             "required_alternatives"
           ] == [["type"], ["activity_type"]]

    refute Map.has_key?(
             Enum.find(fields, &(&1["path"] == "$.outputs.[]")),
             "stable_id_pattern"
           )

    assert Enum.find(fields, &(&1["path"] == "$.candidate_refresh.remaining_horizon"))[
             "required_children"
           ] == ["output_step_s"]
  end

  test "writes a JSON manifest field reference artifact" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_manifest_reference_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.manifest.reference")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.manifest.reference", ["--output", output_path])
    end)

    assert %{
             "schema_contract" => "study_manifest.v1",
             "reference_mode" => "study_manifest_schema_field_reference",
             "compatibility_policy_version" => compatibility_policy_version,
             "identity_policy_version" => identity_policy_version,
             "identity_policy" => identity_policy,
             "field_count" => field_count,
             "supported" => %{"lint_error_codes" => lint_error_codes},
             "fields" => fields
           } =
             output_path
             |> File.read!()
             |> :json.decode()

    assert compatibility_policy_version == Schema.compatibility_policy()["policy_version"]
    assert identity_policy_version == Schema.identity_policy()["policy_version"]
    assert identity_policy["stable_id_pattern"] == Schema.identity_policy()["stable_id_pattern"]
    assert field_count > 50
    assert "invalid_run_option" in lint_error_codes
    assert Enum.any?(fields, &(&1["path"] == "$.candidate_refresh"))

    assert {:ok, %{"schema_contract" => "manifest_field_reference.v1"}} =
             Schema.lint_file(output_path,
               schema_contract: "manifest_field_reference.v1"
             )
  end

  test "schema validation rejects inconsistent manifest reference row evidence" do
    reference = Manifest.field_reference()

    mismatched_count = Map.put(reference, "field_count", reference["field_count"] + 1)

    assert {:error, count_report} = Schema.validate_artifact(mismatched_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.field_count" and &1["message"] =~ "must equal")
           )

    missing_row_identity =
      update_in(reference, ["fields", Access.at(0)], &Map.delete(&1, "path"))

    assert {:error, row_report} = Schema.validate_artifact(missing_row_identity)

    assert Enum.any?(row_report["errors"], &(&1["path"] == "$.fields[0].path"))
  end

  test "schema validation rejects broken manifest reference row links" do
    reference = Manifest.field_reference()

    duplicate_path =
      update_in(reference, ["fields", Access.at(1), "path"], fn _path ->
        get_in(reference, ["fields", Access.at(0), "path"])
      end)

    assert {:error, duplicate_report} = Schema.validate_artifact(duplicate_path)
    assert Enum.any?(duplicate_report["errors"], &(&1["path"] == "$.fields"))

    broken_parent =
      put_in(reference, ["fields", Access.at(1), "parent_path"], "$.missing_parent")

    assert {:error, parent_report} = Schema.validate_artifact(broken_parent)
    assert Enum.any?(parent_report["errors"], &(&1["path"] == "$.fields[1].parent_path"))

    wrong_section = put_in(reference, ["fields", Access.at(0), "section"], "wrong_section")

    assert {:error, section_report} = Schema.validate_artifact(wrong_section)
    assert Enum.any?(section_report["errors"], &(&1["path"] == "$.fields[0].section"))

    wrong_array_marker =
      put_in(reference, ["fields", Access.at(0), "array_item"], true)

    assert {:error, array_report} = Schema.validate_artifact(wrong_array_marker)
    assert Enum.any?(array_report["errors"], &(&1["path"] == "$.fields[0].array_item"))
  end

  test "schema validation rejects inconsistent manifest reference top-level routing" do
    reference = Manifest.field_reference()

    schema_version_index =
      Enum.find_index(reference["fields"], &(&1["path"] == "$.schema_version"))

    candidate_refresh_index =
      Enum.find_index(reference["fields"], &(&1["path"] == "$.candidate_refresh"))

    missing_required_field =
      update_in(reference, ["top_level_required"], &["not_a_top_level_field" | &1])

    assert {:error, missing_required_report} = Schema.validate_artifact(missing_required_field)

    assert Enum.any?(
             missing_required_report["errors"],
             &(&1["path"] == "$.top_level_required[0]")
           )

    required_flag_mismatch =
      put_in(reference, ["fields", Access.at(schema_version_index), "required"], false)

    assert {:error, required_flag_report} = Schema.validate_artifact(required_flag_mismatch)

    assert Enum.any?(
             required_flag_report["errors"],
             &(&1["path"] == "$.top_level_required[0]" and
                 &1["message"] =~ "required field row")
           )

    missing_activation_section =
      update_in(reference, ["activation_sections"], &["not_a_section" | &1])

    assert {:error, missing_activation_report} =
             Schema.validate_artifact(missing_activation_section)

    assert Enum.any?(
             missing_activation_report["errors"],
             &(&1["path"] == "$.activation_sections[0]")
           )

    activation_section_mismatch =
      put_in(
        reference,
        ["fields", Access.at(candidate_refresh_index), "section"],
        "wrong_section"
      )

    assert {:error, activation_section_report} =
             Schema.validate_artifact(activation_section_mismatch)

    assert Enum.any?(
             activation_section_report["errors"],
             &(&1["path"] == "$.activation_sections[3]" and
                 &1["message"] =~ "activated field section")
           )
  end

  test "schema validation rejects supported vocabularies that drift from field enums" do
    reference = Manifest.field_reference()

    invalid_supported_output =
      update_in(reference, ["supported", "outputs"], &["unknown_output" | &1])

    assert {:error, output_report} = Schema.validate_artifact(invalid_supported_output)

    assert Enum.any?(
             output_report["errors"],
             &(&1["path"] == "$.supported.outputs" and
                 &1["message"] =~ "manifest schema enum")
           )

    invalid_supported_propagator =
      update_in(reference, ["supported", "propagators"], &Enum.drop(&1, 1))

    assert {:error, propagator_report} =
             Schema.validate_artifact(invalid_supported_propagator)

    assert Enum.any?(
             propagator_report["errors"],
             &(&1["path"] == "$.supported.propagators" and
                 &1["message"] =~ "manifest schema enum")
           )

    outputs_row_index = Enum.find_index(reference["fields"], &(&1["path"] == "$.outputs.[]"))

    missing_enum =
      update_in(reference, ["fields", Access.at(outputs_row_index)], &Map.delete(&1, "enum"))

    assert {:error, missing_enum_report} = Schema.validate_artifact(missing_enum)

    assert Enum.any?(
             missing_enum_report["errors"],
             &(&1["path"] == "$.supported.outputs" and
                 &1["message"] =~ "field enum evidence")
           )

    invalid_supported_objective =
      update_in(reference, ["supported", "search_objectives"], &Enum.drop(&1, 1))

    assert {:error, objective_report} =
             Schema.validate_artifact(invalid_supported_objective)

    assert Enum.any?(
             objective_report["errors"],
             &(&1["path"] == "$.supported.search_objectives" and
                 &1["message"] =~ "manifest schema enum")
           )
  end

  test "exported schema describes manifest reference field rows" do
    assert {:ok, schema} = Schema.json_schema("manifest_field_reference.v1")

    field_row = get_in(schema, ["properties", "fields", "items"])

    assert field_row["required"] == [
             "path",
             "parent_path",
             "section",
             "type",
             "required",
             "array_item"
           ]

    assert get_in(field_row, ["properties", "path", "type"]) == "string"
    assert get_in(field_row, ["properties", "required", "type"]) == "boolean"

    assert get_in(field_row, ["properties", "type", "oneOf", Access.at(1), "items", "type"]) ==
             "string"

    supported = get_in(schema, ["properties", "supported"])

    assert supported["required"] == [
             "lint_error_codes",
             "outputs",
             "propagators",
             "search_objectives"
           ]

    assert get_in(supported, ["properties", "search_objectives", "items", "type"]) == "string"
    assert supported["additionalProperties"] == false
  end

  test "rejects unsupported output formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.manifest.reference") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.manifest.reference", ["--format", "xml"])
    end
  end
end
