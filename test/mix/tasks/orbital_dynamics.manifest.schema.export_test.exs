defmodule Mix.Tasks.OrbitalDynamics.Manifest.Schema.ExportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.{Schema, Study.Manifest}

  test "exports the study manifest JSON Schema" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_manifest_schema_export_#{System.unique_integer([:positive])}"
      )

    output_path = Path.join([output_root, "nested", "study_manifest.v1.schema.json"])

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.manifest.schema.export")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.manifest.schema.export", ["--output", output_path])
      end)

    assert output =~ "OrbitalDynamics manifest schema export"
    assert output =~ "wrote: #{output_path}"

    assert File.read!(output_path) == json_bytes(Manifest.json_schema())
    assert_no_temp_residue!(Path.dirname(output_path))

    schema = output_path |> File.read!() |> :json.decode()

    assert %{
             "$schema" => "https://json-schema.org/draft/2020-12/schema",
             "required" => ["schema_version", "study_id", "outputs"],
             "properties" => %{
               "schema_version" => %{"const" => 1},
               "campaign" => %{"type" => "object"},
               "candidate_refresh" => %{
                 "required" => ["remaining_horizon"],
                 "properties" => %{
                   "accepted_planning_state" => %{
                     "description" =>
                       "Embedded accepted_planning_state.v1 artifact accepted by the manifest loader."
                   },
                   "orbit_data" => %{
                     "required" => [
                       "snapshot_id",
                       "accepted_at",
                       "state_estimates",
                       "source",
                       "quality",
                       "provenance"
                     ]
                   }
                 }
               }
             },
             "x-orbital-dynamics" => %{
               "schema_contract" => "study_manifest.v1",
               "executable_validator" =>
                 "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2",
               "lint_error_codes" => lint_error_codes,
               "compatibility_policy" => compatibility_policy,
               "identity_policy" => identity_policy,
               "nested_contracts" => [
                 "accepted_planning_state.v1",
                 "resource_summary.v1",
                 "station_calendar_provider.v1"
               ]
             }
           } = schema

    assert "invalid_run_option" in lint_error_codes
    assert "missing_run_option" in lint_error_codes
    assert compatibility_policy == Schema.compatibility_policy()
    assert identity_policy == Schema.identity_policy()

    activity_schema =
      get_in(schema, [
        "properties",
        "mission_plans",
        "items",
        "properties",
        "activities",
        "items",
        "properties"
      ])

    assert get_in(schema, [
             "properties",
             "mission_plans",
             "items",
             "properties",
             "activities",
             "items",
             "required"
           ]) == ["id"]

    assert get_in(schema, [
             "properties",
             "mission_plans",
             "items",
             "properties",
             "activities",
             "items",
             "anyOf"
           ]) == [%{"required" => ["type"]}, %{"required" => ["activity_type"]}]

    assert get_in(activity_schema, ["spacecraft", "properties", "id", "type"]) == "string"

    assert get_in(activity_schema, ["spacecraft", "properties", "spacecraft_id", "type"]) ==
             "string"

    assert get_in(activity_schema, ["spacecraft", "properties", "satellite_id", "type"]) ==
             "string"

    assert get_in(activity_schema, ["satellite", "properties", "id", "type"]) == "string"

    assert get_in(activity_schema, ["activity_type", "enum"]) ==
             get_in(activity_schema, ["type", "enum"])

    assert get_in(activity_schema, ["battery_energy_generated_wh"]) == %{
             "type" => "number",
             "minimum" => 0.0
           }

    assert get_in(activity_schema, ["eclipse_overlap_fraction", "type"]) == "number"
    assert get_in(activity_schema, ["eclipse_overlap_s", "type"]) == "number"
    assert get_in(activity_schema, ["lighting_condition", "type"]) == "string"
    assert get_in(activity_schema, ["lighting_condition_detail", "type"]) == "string"
    assert get_in(activity_schema, ["lighting_condition_model", "type"]) == "string"
    assert get_in(activity_schema, ["lighting_detail_model", "type"]) == "string"
    assert get_in(activity_schema, ["lighting_confidence", "type"]) == ["number", "string"]
    assert get_in(activity_schema, ["target_priority", "type"]) == "number"
    assert get_in(activity_schema, ["target_priority_source", "type"]) == "string"
    assert get_in(activity_schema, ["target_priority_objective_ids", "type"]) == "array"
    assert get_in(activity_schema, ["target_priority_objective_type", "type"]) == "string"
    assert get_in(activity_schema, ["contact_success", "type"]) == "boolean"
    assert get_in(activity_schema, ["contact_result", "type"]) == "string"
    assert get_in(activity_schema, ["contact_success_factor", "type"]) == "number"
    assert get_in(activity_schema, ["command_success", "type"]) == "boolean"
    assert get_in(activity_schema, ["command_result", "type"]) == "string"
    assert get_in(activity_schema, ["command_success_factor", "type"]) == "number"
    assert get_in(activity_schema, ["observation_success", "type"]) == "boolean"
    assert get_in(activity_schema, ["observation_result", "type"]) == "string"
    assert get_in(activity_schema, ["observation_success_factor", "type"]) == "number"
    assert get_in(activity_schema, ["maneuver_success", "type"]) == "boolean"
    assert get_in(activity_schema, ["maneuver_result", "type"]) == "string"
    assert get_in(activity_schema, ["maneuver_success_factor", "type"]) == "number"
    assert get_in(activity_schema, ["feedback_weight", "type"]) == "number"
    assert get_in(activity_schema, ["feedback_weight_source", "type"]) == "string"
    assert get_in(activity_schema, ["command_window_id", "type"]) == "string"
    assert get_in(activity_schema, ["command_window_type", "type"]) == "string"
    assert get_in(activity_schema, ["window_type", "type"]) == "string"
    assert get_in(activity_schema, ["command_window", "type"]) == "object"
    assert "cmd" in get_in(activity_schema, ["direction", "enum"])
    assert "Health Check Window" in get_in(activity_schema, ["direction", "enum"])

    assert get_in(activity_schema, [
             "direction",
             "x-orbital-dynamics",
             "provider_aliases",
             "track_ing"
           ]) == "tracking"

    prior_candidate_direction_schema =
      get_in(schema, [
        "properties",
        "candidate_refresh",
        "properties",
        "prior_candidate_activities",
        "items",
        "properties",
        "direction"
      ])

    assert "health_check" in prior_candidate_direction_schema["enum"]
    assert "Health Check Window" in prior_candidate_direction_schema["enum"]

    assert get_in(prior_candidate_direction_schema, [
             "x-orbital-dynamics",
             "provider_aliases",
             "cmd"
           ]) == "command"

    prior_candidate_schema =
      get_in(schema, [
        "properties",
        "candidate_refresh",
        "properties",
        "prior_candidate_activities",
        "items",
        "properties"
      ])

    assert get_in(prior_candidate_schema, ["station", "properties", "id", "type"]) == "string"
    assert get_in(prior_candidate_schema, ["activity_type", "type"]) == "string"

    assert get_in(prior_candidate_schema, [
             "ground_station",
             "properties",
             "ground_station_id",
             "type"
           ]) == "string"

    assert get_in(prior_candidate_schema, ["start_s", "type"]) == "number"
    assert get_in(prior_candidate_schema, ["end_s", "type"]) == "number"

    realized_activity_schema =
      get_in(schema, [
        "properties",
        "candidate_refresh",
        "properties",
        "operational_feedback",
        "properties",
        "realized_activities",
        "items",
        "properties"
      ])

    assert get_in(realized_activity_schema, ["battery_energy_generated_wh"]) == %{
             "type" => "number",
             "minimum" => 0.0
           }

    search_objectives =
      get_in(schema, ["properties", "search", "properties", "objective", "enum"])

    monte_carlo_objectives =
      get_in(schema, ["properties", "monte_carlo", "properties", "objective", "enum"])

    assert "total_delta_v_km_s" in search_objectives
    assert search_objectives == monte_carlo_objectives
  end

  test "rejects a directory output target without temp residue" do
    output_root =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_manifest_schema_directory_target_#{System.unique_integer([:positive])}"
      )

    output_path = Path.join(output_root, "study_manifest.v1.schema.json")

    on_exit(fn ->
      File.rm_rf(output_root)
      Mix.Task.reenable("orbital_dynamics.manifest.schema.export")
    end)

    File.mkdir_p!(output_path)

    assert_raise ArgumentError, ~r/unsupported_target.*directory/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.manifest.schema.export", ["--output", output_path])
      end)
    end

    assert_no_temp_residue!(output_root)
  end

  test "requires an output path" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.manifest.schema.export") end)

    assert_raise Mix.Error, ~r/--output is required/, fn ->
      Mix.Task.run("orbital_dynamics.manifest.schema.export", [])
    end
  end

  defp json_bytes(value) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  defp assert_no_temp_residue!(directory) do
    assert Path.wildcard(Path.join(directory, ".orbital_dynamics-safe-output-*.tmp")) == []
  end
end
