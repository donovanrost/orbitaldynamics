defmodule OrbitalDynamics.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.{ContactAllocation, ContactFilter}
  alias OrbitalDynamics.EventDetectors.AccessWindows

  alias OrbitalDynamics.Propagators.{
    J2,
    J2ExlaCpu,
    TwoBody,
    TwoBodyDrag,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  alias OrbitalDynamics.{ResourceFilter, Schema}

  test "public capability catalog exposes declared model metadata by product area" do
    catalog = OrbitalDynamics.capability_catalog()

    assert catalog.analysis.propagator == TwoBody.capabilities()

    assert catalog.analysis.force_models.atmospheric_drag ==
             OrbitalDynamics.ForceModels.AtmosphericDrag.capabilities()

    assert catalog.analysis.propagators.two_body == TwoBody.capabilities()
    assert catalog.analysis.propagators.two_body_drag == TwoBodyDrag.capabilities()
    assert catalog.analysis.propagators.j2 == J2.capabilities()
    assert catalog.analysis.propagators.two_body_nx == TwoBodyNx.capabilities()
    assert catalog.analysis.propagators.two_body_nx_compiled == TwoBodyNxCompiled.capabilities()
    assert catalog.analysis.propagators.two_body_exla_cpu == TwoBodyExlaCpu.capabilities()
    assert catalog.analysis.propagators.j2_exla_cpu == J2ExlaCpu.capabilities()
    assert catalog.analysis.access_windows == AccessWindows.capabilities()
    assert catalog.analysis.orbit_data == OrbitalDynamics.OrbitData.capabilities()
    assert catalog.planning.activity_templates.artifact_contract == "activity_template.v1"
    assert catalog.planning.activity_templates.template_count == 6
    assert catalog.planning.activity_templates.output_shape == :normalized_timeline_activity
    assert catalog.planning.activity_templates.transition_path == :timeline_transition_application

    assert catalog.planning.activity_templates.subsystem_state_hint_fields == [
             "required_states",
             "produced_states"
           ]

    assert catalog.planning.activity_templates.public_facades == [
             :activity_templates,
             :activity_template,
             :activity_from_template
           ]

    assert catalog.planning.activity_templates.supported_activity_types == [
             "command",
             "downlink",
             "health_check",
             "impulsive_burn",
             "observe",
             "slew"
           ]

    assert "template:observe:basic" in catalog.planning.activity_templates.template_ids
    assert catalog.planning.candidate_refresh == OrbitalDynamics.CandidateRefresh.capabilities()
    assert catalog.planning.search.grid == OrbitalDynamics.Search.Grid.capabilities()
    assert catalog.planning.search.local == OrbitalDynamics.Search.Local.capabilities()
    assert catalog.planning.search.monte_carlo == OrbitalDynamics.Search.MonteCarlo.capabilities()

    assert [
             %{
               "schema_contract" => "subsystem_model_capability.v1",
               "subsystem" => "power",
               "model" => "battery_energy_storage_planning_grade",
               "fidelity_tier" => "planning_grade"
             },
             %{
               "schema_contract" => "subsystem_model_capability.v1",
               "subsystem" => "data_recorder",
               "model" => "data_storage_buffer_planning_grade",
               "fidelity_tier" => "planning_grade"
             }
           ] = catalog.planning.subsystem_models

    assert :operational_timeline_report in catalog.operations.timeline.public_facades
    assert :timeline_diff_report in catalog.operations.timeline.public_facades
    assert :timeline_link in catalog.operations.timeline.public_facades
    assert catalog.operations.contact_allocation == ContactAllocation.capabilities()
    assert :contact_intents_from_activities in catalog.operations.contact_intent.public_facades
    assert :contact_intent_from_activity! in catalog.operations.contact_intent.public_facades
    assert :contact_intent_summary in catalog.operations.contact_intent.public_facades
    assert :resource_filter_policy in catalog.operations.resource_filter.public_facades
    assert catalog.operations.policy == OrbitalDynamics.Policy.capabilities()
    assert catalog.operations.cadence_import == OrbitalDynamics.CadenceImport.capabilities()

    assert catalog.constraints.artifact_metric ==
             OrbitalDynamics.Constraints.ArtifactMetric.capabilities()

    assert catalog.constraints.campaign_local ==
             OrbitalDynamics.Constraints.CampaignLocal.capabilities()

    assert catalog.validation.schema == Schema.capabilities()
    assert catalog.reporting.result_set == OrbitalDynamics.ResultSet.Report.capabilities()

    assert catalog.reporting.study_benchmark ==
             OrbitalDynamics.Study.Benchmark.Report.capabilities()

    assert catalog.reporting.study_benchmark.public_facades == [:study_benchmark_summary]

    assert "total_delta_v_km_s" in catalog.reporting.result_set.supported_objectives
    assert "campaign_plan.v1" in catalog.validation.schema.artifact_contracts
    assert "cadence_import_manifest.v1" in catalog.validation.schema.artifact_contracts
    assert "operator_review_package.v1" in catalog.validation.schema.artifact_contracts
    assert "schema_validation_report.v1" in catalog.validation.schema.validation_report_contracts
    assert catalog.validation.schema.artifact_contract_count == map_size(Schema.contracts())
    assert catalog.validation.schema.compatibility_policy_version == 1
    assert catalog.validation.schema.identity_policy_version == 1

    assert "executable_elixir_validator_is_source_of_truth" in catalog.validation.schema.known_limits

    assert :constraint_report in catalog.constraints.artifact_metric.outputs
    assert :constraint_report in catalog.constraints.campaign_local.outputs
    assert catalog.planning.search.monte_carlo.deterministic_seed == true

    assert [
             %{
               "schema_contract" => "environment_model_capability.v1",
               "model" => "fixed_inertial_solar_direction"
             },
             %{
               "schema_contract" => "environment_model_capability.v1",
               "model" => "constant_earth_rotation"
             }
           ] = catalog.environment.models

    assert [
             %{
               "schema_contract" => "environment_provider_capability.v1",
               "model" => "fixed_inertial_solar_direction"
             }
             | _
           ] = catalog.environment.providers
  end

  test "public capability catalog artifact is JSON-facing and schema-valid" do
    artifact = OrbitalDynamics.capability_catalog_artifact()

    assert %{
             "schema_contract" => "capability_catalog.v1",
             "schema_version" => 1,
             "model" => "public_capability_catalog",
             "validation" => %{
               "schema" => %{
                 "artifact_contracts" => artifact_contracts,
                 "artifact_contract_count" => artifact_contract_count
               }
             }
           } = artifact

    assert artifact_contract_count == map_size(Schema.contracts())
    assert artifact_contract_count == length(artifact_contracts)
    assert "capability_catalog.v1" in artifact_contracts

    assert :null =
             get_in(artifact, [
               "environment",
               "providers",
               Access.at(0),
               "coverage",
               "starts_at_s"
             ])

    assert :null =
             get_in(artifact, ["environment", "providers", Access.at(0), "coverage", "ends_at_s"])

    refute artifact |> :json.encode() |> IO.iodata_to_binary() =~ ~s("nil")

    assert {:ok, %{"schema_contract" => "capability_catalog.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, capability_catalog_schema} = Schema.json_schema("capability_catalog.v1")

    assert get_in(capability_catalog_schema, ["properties", "model", "const"]) ==
             "public_capability_catalog"

    stale_model_artifact = Map.put(artifact, "model", "stale_capability_catalog")

    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model_artifact)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"public_capability_catalog\"")
           )
  end

  test "public activity template helper exposes deterministic schema-valid baseline templates" do
    templates = OrbitalDynamics.activity_templates()

    assert Enum.map(templates, & &1["id"]) == [
             "template:observe:basic",
             "template:downlink:basic",
             "template:command:basic",
             "template:health_check:basic",
             "template:slew:basic",
             "template:impulsive_burn:basic"
           ]

    supported_activity_types =
      OrbitalDynamics.Timeline.capabilities().supported_activity_types
      |> MapSet.new()

    for template <- templates do
      assert template["schema_contract"] == "activity_template.v1"
      assert template["validation_level"] == "artifact_contract"
      assert template["activity_type"] in supported_activity_types

      assert template["field_count"] ==
               template["required_field_count"] + template["optional_field_count"]

      declared_fields =
        template["required_fields"]
        |> MapSet.new()
        |> MapSet.union(MapSet.new(template["optional_fields"]))

      assert template["default_fields"]
             |> Map.keys()
             |> Enum.all?(&MapSet.member?(declared_fields, &1))

      assert template["operational_hints"]["setup_duration_s"] >= 0.0
      assert template["operational_hints"]["cooldown_duration_s"] >= 0.0
      assert is_boolean(template["operational_hints"]["telemetry_confirmation_required"])
      assert is_binary(template["operational_hints"]["telemetry_confirmation_status"])

      assert is_map(template["subsystem_state_hints"])
      assert is_list(template["subsystem_state_hints"]["required_states"])
      assert is_list(template["subsystem_state_hints"]["produced_states"])

      for state_hint <-
            template["subsystem_state_hints"]["required_states"] ++
              template["subsystem_state_hints"]["produced_states"] do
        assert is_binary(state_hint["subsystem"])
        assert is_binary(state_hint["state"])
      end

      assert {:ok, %{"schema_contract" => "activity_template.v1", "status" => "pass"}} =
               Schema.validate_artifact(template)
    end

    observe_template = hd(templates)

    assert OrbitalDynamics.activity_template("template:observe:basic") == {:ok, observe_template}
    assert OrbitalDynamics.activity_template("observe") == {:ok, observe_template}
    assert OrbitalDynamics.activity_template("payload_warmup") == :error
    assert OrbitalDynamics.activity_template(:observe) == :error

    observe_fixture =
      "study_results/activity_template_v1.json"
      |> File.read!()
      |> :json.decode()

    assert observe_fixture == observe_template
  end

  test "public activity template instantiation returns transition-ready timeline rows" do
    assert {:ok, observe} = OrbitalDynamics.activity_template("observe")

    fields = %{
      id: :obs_template_transition,
      target_id: :target_alpha,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      dependency_activity_ids: [:health_gate],
      exclusive_with_activity_ids: [:downlink_conflict],
      metadata: %{timeline_id: :"timeline:obs_template_transition"}
    }

    assert {:ok,
            %{
              "activity_id" => "obs_template_transition",
              "activity_type" => "observe",
              "status" => "planned",
              "approval_status" => "not_evaluated",
              "locked" => false,
              "allow_overlap" => false,
              "setup_duration_s" => 120.0,
              "cooldown_duration_s" => 60.0,
              "telemetry_confirmation_required" => true,
              "telemetry_confirmation_status" => "required",
              "timeline_id" => "timeline:obs_template_transition",
              "target_id" => "target_alpha",
              "dependency_activity_ids" => ["health_gate"],
              "exclusive_with_activity_ids" => ["downlink_conflict"],
              "activity_template" => %{
                "schema_contract" => "activity_template.v1",
                "id" => "template:observe:basic",
                "activity_type" => "observe",
                "template_version" => 1,
                "validation_level" => "artifact_contract"
              },
              "activity_context" => %{
                "dependency_activity_ids" => ["health_gate"],
                "exclusive_with_activity_ids" => ["downlink_conflict"],
                "activity_template" => %{
                  "id" => "template:observe:basic",
                  "activity_type" => "observe"
                },
                "setup_duration_s" => 120.0,
                "cooldown_duration_s" => 60.0,
                "telemetry_confirmation_required" => true,
                "telemetry_confirmation_status" => "required"
              }
            } = replacement} = OrbitalDynamics.activity_from_template("observe", fields)

    assert OrbitalDynamics.activity_from_template(observe, fields) == {:ok, replacement}

    assert replacement["activity_template"]["subsystem_state_hints"] ==
             observe["subsystem_state_hints"]

    assert get_in(replacement, ["activity_context", "activity_template", "subsystem_state_hints"]) ==
             observe["subsystem_state_hints"]

    assert %{
             "schema_contract" => "timeline_integrity_report.v1",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["health_gate"],
             "dependency_review_activity_ids" => ["obs_template_transition"],
             "rows" => [
               %{
                 "activity_template" => %{
                   "schema_contract" => "activity_template.v1",
                   "id" => "template:observe:basic",
                   "activity_type" => "observe",
                   "template_version" => 1,
                   "validation_level" => "artifact_contract"
                 },
                 "activity_context" => %{
                   "activity_template" => %{
                     "id" => "template:observe:basic",
                     "activity_type" => "observe"
                   }
                 }
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation"
             }
           } = integrity_report = OrbitalDynamics.timeline_integrity_report([replacement])

    assert {:ok, %{"schema_contract" => "timeline_integrity_report.v1"}} =
             Schema.validate_artifact(integrity_report)

    assert get_in(integrity_report, [
             "rows",
             Access.at(0),
             "activity_context",
             "activity_template",
             "subsystem_state_hints"
           ]) == observe["subsystem_state_hints"]

    source = %{
      id: :obs_template_transition,
      type: :observe,
      target_id: :target_alpha,
      starts_at_s: 8.0,
      ends_at_s: 18.0,
      dependency_activity_ids: [:health_gate],
      exclusive_with_activity_ids: [:downlink_conflict],
      metadata: %{timeline_id: :"timeline:obs_template_transition"}
    }

    assert %{
             "transition_decision" => "review",
             "application_status" => "operator_review_required",
             "requires_operator_review" => true,
             "required_operator_action" => "review_timeline_change",
             "changed_fields" => changed_fields
           } = OrbitalDynamics.timeline_transition_application(source, replacement)

    assert "allow_overlap" in changed_fields
    assert "starts_at_s" in changed_fields
    assert "ends_at_s" in changed_fields
    assert "setup_duration_s" in changed_fields
    assert "cooldown_duration_s" in changed_fields
    assert "telemetry_confirmation_required" in changed_fields
    assert "telemetry_confirmation_status" in changed_fields

    assert %{
             "schema_contract" => "timeline_transition_application_report.v1",
             "transition_decision_counts" => %{"review" => 1},
             "selected_activity_count" => 0,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation"
             }
           } =
             report =
             OrbitalDynamics.timeline_transition_application_report([source], [replacement])

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok,
            %{
              "activity_type" => "downlink",
              "allow_overlap" => false,
              "activity_template" => %{"id" => "template:downlink:basic"}
            }} =
             OrbitalDynamics.activity_from_template("template:downlink:basic", %{
               id: :downlink_from_template,
               ground_station_id: :gs_1,
               starts_at_s: 30.0,
               ends_at_s: 40.0
             })

    assert {:error, %{reason: "unknown_activity_template"}} =
             OrbitalDynamics.activity_from_template("payload_warmup", fields)

    assert {:error,
            %{
              reason: "missing_required_activity_template_fields",
              fields: ["target_id"]
            }} =
             OrbitalDynamics.activity_from_template("observe", Map.delete(fields, :target_id))

    assert {:error,
            %{
              reason: "undeclared_activity_template_fields",
              fields: ["operator_note"]
            }} =
             OrbitalDynamics.activity_from_template(
               "observe",
               Map.put(fields, :operator_note, "go")
             )

    assert {:error,
            %{
              reason: "activity_template_type_mismatch",
              activity_type: "downlink",
              template_activity_type: "observe"
            }} =
             OrbitalDynamics.activity_from_template("observe", Map.put(fields, :type, "downlink"))

    invalid_template = Map.put(observe, "activity_type", "payload_warmup")

    assert {:error,
            %{
              reason: "invalid_activity_template",
              validation_report: %{
                "schema_contract" => "activity_template.v1",
                "status" => "fail"
              }
            }} = OrbitalDynamics.activity_from_template(invalid_template, fields)
  end

  test "public capability facades resolve to exported top-level functions" do
    missing_facades =
      OrbitalDynamics.capability_catalog()
      |> public_facade_entries()
      |> Enum.flat_map(fn {path, facades} ->
        facades
        |> Enum.reject(&exported_orbital_dynamics_facade?/1)
        |> Enum.map(&{path, &1})
      end)

    assert missing_facades == []
  end

  test "filter capability suppression reasons are schema-visible" do
    capability_reasons =
      (ContactFilter.capabilities().suppression_reasons ++
         ResourceFilter.capabilities().suppression_reasons)
      |> Enum.uniq()
      |> Enum.sort()

    for contract <- ["contact_filter_report.v1", "resource_filter_report.v1"] do
      assert {:ok, schema} = Schema.json_schema(contract)

      schema_reasons =
        schema
        |> get_in([
          "properties",
          "suppressed_candidates",
          "items",
          "properties",
          "suppressed_reason",
          "enum"
        ])
        |> Enum.sort()

      assert schema_reasons == capability_reasons
    end
  end

  defp public_facade_entries(value, path \\ [])

  defp public_facade_entries(%{} = value, path) do
    current =
      case Map.get(value, :public_facades) do
        facades when is_list(facades) -> [{Enum.reverse(path), facades}]
        _value -> []
      end

    nested =
      value
      |> Enum.flat_map(fn
        {key, nested_value} when is_atom(key) or is_binary(key) ->
          public_facade_entries(nested_value, [key | path])

        _entry ->
          []
      end)

    current ++ nested
  end

  defp public_facade_entries(_value, _path), do: []

  defp exported_orbital_dynamics_facade?(facade) when is_atom(facade) do
    Enum.any?(0..5, &function_exported?(OrbitalDynamics, facade, &1))
  end

  defp exported_orbital_dynamics_facade?(_facade), do: false
end
