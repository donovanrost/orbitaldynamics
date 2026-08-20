Code.require_file("../../orbital_dynamics/campaign_planner/support.exs", __DIR__)
Code.require_file("../../orbital_dynamics/campaign_planner/local_search_support.exs", __DIR__)

defmodule Mix.Tasks.OrbitalDynamics.Level5WorkflowTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias OrbitalDynamics.AuthorityContext
  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CampaignPlanner.LocalSearchSupport, as: HardSupport
  alias OrbitalDynamics.CampaignPlanner.TestSupport, as: Support
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Study.Manifest

  @workflow_doc "docs/feature_set/level5_workflow.md"
  @output_root "${OUTPUT_ROOT}"
  @tmp_prefix "orbital_dynamics_level5_workflow_"
  @ownership_marker ".orbital_dynamics_level5_workflow_owner"
  @tmp_creation_attempts 32

  defmodule ExactNoWriteAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    @impl true
    def capabilities do
      %{
        "contract" => "cadence_consumer_dry_run_adapter.v1",
        "operations" => ["dry_run"],
        "writes" => false
      }
    end

    @impl true
    def dry_run(request, opts) do
      send(self(), {:level5_cadence_dry_run, request, opts})

      {:ok,
       %{
         "status" => "conformant",
         "source_identity" => request["source_identity"],
         "authority_evidence" => request["authority_evidence"],
         "manifest_semantic_sha256" => request["manifest_semantic_sha256"],
         "idempotency_identity" => request["idempotency_identity"]
       }}
    end
  end

  @tag timeout: 120_000
  test "checked JSON index links and executes the bounded V1 V2 V3 workflow" do
    index = workflow_index!()

    assert index["index_contract"] == "orbital_dynamics.level5_workflow.v1"
    assert index["index_version"] == 1
    assert index["level"] == 5
    assert index["execution"]["mode"] == "synchronous_in_caller"
    assert index["execution"]["checked_fixtures_mutated"] == false

    assert Enum.map(index["workflows"], & &1["id"]) == index["execution"]["order"]

    validate_documentation_links!(index)
    validate_referenced_tasks!(index)
    validate_inputs!(index)

    {tmp_root, ownership_token} = create_owned_tmp_root!()

    on_exit(fn ->
      try do
        reenable_referenced_tasks!(index)
      after
        cleanup_owned_tmp_root!(tmp_root, ownership_token)
      end
    end)

    execute_indexed_support_commands!(index, tmp_root)

    outputs =
      for workflow <- index["workflows"] do
        task = workflow["task"]
        argv = materialize_paths(workflow["argv"], tmp_root)
        output_path = materialize_path(workflow["output"], tmp_root)

        assert Path.dirname(output_path) == tmp_root
        assert output_path in argv

        Mix.Task.reenable(task)

        summary =
          capture_io(fn -> Mix.Task.run(task, argv) end)
          |> String.trim()
          |> :json.decode()

        assert summary["output"] == output_path
        assert_index_assertions!(summary, workflow["expected_output"]["summary_assertions"])

        artifact = output_path |> File.read!() |> :json.decode()
        expected = workflow["expected_output"]

        assert artifact["schema_version"] == expected["schema_version"]

        assert {:ok,
                %{
                  "schema_contract" => expected_contract,
                  "schema_version" => expected_version,
                  "status" => "pass"
                }} =
                 Schema.validate_artifact(artifact,
                   contract: expected["validation_contract"]
                 )

        assert expected_contract == expected["validation_contract"]
        assert expected_version == expected["schema_version"]
        assert_index_assertions!(artifact, expected["assertions"])

        output_path
      end

    assert length(outputs) == 3
    assert Enum.uniq(outputs) == outputs
    assert Enum.all?(outputs, &File.regular?/1)

    assert_broken_pinned_source_path!(index, tmp_root)
  end

  test "rejects a missing indexed Mix task" do
    absent_task = "orbital_dynamics.level5_workflow.absent"
    assert is_nil(Mix.Task.get(absent_task))

    index =
      workflow_index!()
      |> put_in(["capability_discovery", "task"], absent_task)

    assert_raise ExUnit.AssertionError, ~r/missing referenced Mix task/, fn ->
      validate_referenced_tasks!(index)
    end
  end

  test "does not accept or delete a pre-existing temp-root candidate" do
    {preexisting_root, preexisting_token} = create_owned_tmp_root!()

    on_exit(fn -> cleanup_owned_tmp_root!(preexisting_root, preexisting_token) end)

    sentinel_path = Path.join(preexisting_root, "preexisting-sentinel")
    File.write!(sentinel_path, "must survive collision retry")

    {selected_root, selected_token} = create_owned_tmp_root!([preexisting_root])

    on_exit(fn -> cleanup_owned_tmp_root!(selected_root, selected_token) end)

    refute selected_root == preexisting_root
    assert File.dir?(preexisting_root)
    assert File.read!(sentinel_path) == "must survive collision retry"
    assert File.read!(Path.join(preexisting_root, @ownership_marker)) == preexisting_token
  end

  test "opt-in hard-eligibility V3 dry-runs identically as artifact and manifest" do
    authority_context =
      AuthorityContext.new!(%{
        "schema_contract" => "authority_context.v1",
        "authority_source" => "mission-operations-authority-registry",
        "source_revision" => "level5-workflow-r1",
        "effective_from" => "2026-05-14T00:00:00Z",
        "valid_until" => "2026-05-15T00:00:00Z",
        "evaluation_time" => "2026-05-14T12:00:00Z"
      })

    prior_plan =
      Support.base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "candidate_activities" => [Support.downlink("dl_1", 100.0, 160.0)]
      })

    strategy_opts = [
      branches: [%{id: "baseline"}, %{id: "alternate", probability: 1.0}],
      mission_state: Support.mission_state([]),
      current_epoch_s: 0.0,
      authority_context_mode: "explicit",
      authority_context: authority_context
    ]

    legacy = Support.strategy(prior_plan, strategy_opts)

    alternatives =
      legacy["branches"]
      |> Enum.with_index()
      |> Enum.map(fn {branch, generation_index} ->
        %{
          "id" => branch["branch_id"],
          "generation_index" => generation_index,
          "parameters" => branch["score_terms"]
        }
      end)

    hard_eligibility =
      HardSupport.hard_feasibility(
        alternatives: alternatives,
        higher_score_infeasible?: false
      )

    artifact =
      Support.strategy(
        prior_plan,
        Keyword.put(strategy_opts, :recommendation_eligibility, hard_eligibility)
      )
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> :json.decode()

    manifest = artifact["cadence_import_manifest"]

    assert artifact["recommendation_eligibility"]["mode"] == "hard"
    assert artifact["recommendation_eligibility"]["eligible_count"] == 2
    assert artifact["recommendation_eligibility"]["rejected_count"] == 0

    assert artifact["recommendation_eligibility"]["selected_branch_id"] in artifact[
             "recommendation_eligibility"
           ]["eligible_ranked_branch_ids"]

    assert artifact["eligibility_status"] == "eligible"
    assert artifact["authority_context"] == authority_context

    recommendation_review =
      Enum.find(
        artifact["operator_review_package"]["rows"],
        &(&1["source"] == "campaign_strategy.recommendation")
      )

    assert recommendation_review["source_recommendation"] == artifact["recommendation"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert ExactNoWriteAdapter.capabilities() == %{
             "contract" => "cadence_consumer_dry_run_adapter.v1",
             "operations" => ["dry_run"],
             "writes" => false
           }

    assert OrbitalDynamics.CadenceImport.Adapter.behaviour_info(:callbacks) |> Enum.sort() ==
             [capabilities: 0, dry_run: 2]

    refute function_exported?(ExactNoWriteAdapter, :create, 1)
    refute function_exported?(ExactNoWriteAdapter, :update, 2)
    refute function_exported?(ExactNoWriteAdapter, :write, 2)
    refute function_exported?(ExactNoWriteAdapter, :mutate, 2)

    assert {:ok, artifact_result} = CadenceImport.dry_run(artifact, ExactNoWriteAdapter)
    assert_receive {:level5_cadence_dry_run, artifact_request, %{}}

    assert {:ok, manifest_result} = CadenceImport.dry_run(manifest, ExactNoWriteAdapter)
    assert_receive {:level5_cadence_dry_run, manifest_request, %{}}
    refute_receive {:level5_cadence_dry_run, _request, _opts}

    authority_evidence =
      Map.take(
        artifact,
        ~w(eligibility_status authority_context authority_context_evaluation)
      )

    assert manifest_request == artifact_request
    assert manifest_result == artifact_result
    assert artifact_result["status"] == "conformant"
    assert artifact_result["conformance"] == manifest_result["conformance"]
    assert artifact_result["idempotency"] == manifest_result["idempotency"]
    assert artifact_result["source_identity"] == manifest_result["source_identity"]
    assert artifact_result["authority_evidence"] == authority_evidence
    assert manifest_result["authority_evidence"] == authority_evidence
    assert artifact_result["conformance"]["writes_permitted"] == false
    assert artifact_result["conformance"]["authority_evidence_preserved"] == true
    assert artifact_result["conformance"]["identity_preserved"] == true
  end

  defp workflow_index! do
    contents = File.read!(@workflow_doc)

    pattern =
      ~r/<!-- level5-workflow-index:begin -->\s*```json\s*(\{.*?\})\s*```\s*<!-- level5-workflow-index:end -->/s

    assert [json] = Regex.run(pattern, contents, capture: :all_but_first)
    assert length(Regex.scan(~r/<!-- level5-workflow-index:begin -->/, contents)) == 1

    :json.decode(json)
  end

  defp validate_documentation_links!(index) do
    for %{"source" => source, "href" => href} <- index["documentation_links"] do
      assert File.regular?(source), "missing workflow link source #{source}"

      resolved = source |> Path.dirname() |> Path.join(href) |> Path.expand()
      assert resolved == Path.expand(@workflow_doc)
      assert File.read!(source) =~ "](#{href})"
    end
  end

  defp validate_referenced_tasks!(index) do
    for task <- referenced_tasks(index) do
      task_module = Mix.Task.get(task)
      refute is_nil(task_module), "missing referenced Mix task #{task}"
      assert is_atom(task_module), "invalid referenced Mix task #{task}"
    end
  end

  defp referenced_tasks(index) do
    [
      index["capability_discovery"]["task"],
      index["schema_registry"]["task"],
      index["study_manifest_schema"]["task"]
    ]
    |> Kernel.++(Enum.map(index["workflows"], & &1["task"]))
    |> Enum.uniq()
  end

  defp reenable_referenced_tasks!(index) do
    Enum.each(referenced_tasks(index), &Mix.Task.reenable/1)
  end

  defp execute_indexed_support_commands!(index, tmp_root) do
    capability = index["capability_discovery"]
    Mix.Task.reenable(capability["task"])

    capability_catalog =
      capture_io(fn -> Mix.Task.run(capability["task"], capability["argv"]) end)
      |> String.trim()
      |> :json.decode()

    assert_capability_expectations!(capability_catalog, capability["expected"])
    assert capability_catalog == json_roundtrip(OrbitalDynamics.capability_catalog_artifact())

    schema_registry = index["schema_registry"]
    schema_argv = materialize_paths(schema_registry["argv"], tmp_root)
    schema_output_path = output_path_from_argv!(schema_argv)
    assert_direct_child!(schema_output_path, tmp_root)
    refute File.exists?(schema_output_path)

    Mix.Task.reenable(schema_registry["task"])

    schema_output =
      capture_io(fn -> Mix.Task.run(schema_registry["task"], schema_argv) end)

    assert schema_output =~ "wrote: #{schema_output_path}"
    assert File.regular?(schema_output_path)

    schema_bundle = schema_output_path |> File.read!() |> :json.decode()
    assert schema_bundle["schema_contract"] == schema_registry["output_contract"]
    assert schema_bundle["schema_count"] == map_size(schema_bundle["schemas"])
    assert schema_bundle["compatibility_policy"] == Schema.compatibility_policy()
    assert schema_bundle["identity_policy"] == Schema.identity_policy()

    assert schema_bundle["compatibility_policy"]["policy_version"] ==
             schema_registry["compatibility_policy_version"]

    assert schema_bundle["identity_policy"]["policy_version"] ==
             schema_registry["identity_policy_version"]

    for expected <- schema_registry["artifact_contracts"] do
      exported_schema = Map.fetch!(schema_bundle["schemas"], expected["contract"])
      assert {:ok, live_contract} = Schema.contract(expected["contract"])
      assert live_contract["schema_version"] == expected["schema_version"]
      assert {:ok, live_schema} = Schema.json_schema(expected["contract"])
      assert exported_schema == json_roundtrip(live_schema)

      assert get_in(exported_schema, ["properties", "schema_version", "const"]) ==
               expected["schema_version"]
    end

    manifest_schema = index["study_manifest_schema"]
    manifest_argv = materialize_paths(manifest_schema["argv"], tmp_root)
    manifest_output_path = output_path_from_argv!(manifest_argv)
    assert_direct_child!(manifest_output_path, tmp_root)
    refute File.exists?(manifest_output_path)

    Mix.Task.reenable(manifest_schema["task"])

    manifest_output =
      capture_io(fn -> Mix.Task.run(manifest_schema["task"], manifest_argv) end)

    assert manifest_output =~ "wrote: #{manifest_output_path}"
    assert File.regular?(manifest_output_path)

    exported_manifest_schema = manifest_output_path |> File.read!() |> :json.decode()
    assert exported_manifest_schema == json_roundtrip(Manifest.json_schema())

    assert get_in(exported_manifest_schema, ["x-orbital-dynamics", "schema_contract"]) ==
             manifest_schema["contract"]

    assert get_in(exported_manifest_schema, ["properties", "schema_version", "const"]) ==
             manifest_schema["schema_version"]

    assert get_in(exported_manifest_schema, [
             "x-orbital-dynamics",
             "compatibility_policy",
             "policy_version"
           ]) == manifest_schema["compatibility_policy_version"]

    assert get_in(exported_manifest_schema, [
             "x-orbital-dynamics",
             "identity_policy",
             "policy_version"
           ]) == manifest_schema["identity_policy_version"]
  end

  defp assert_capability_expectations!(catalog, expected) do
    schema_capability = catalog["validation"]["schema"]

    assert catalog["schema_contract"] == expected["schema_contract"]
    assert catalog["schema_version"] == expected["schema_version"]
    assert schema_capability["artifact_contract_count"] == expected["artifact_contract_count"]

    assert schema_capability["compatibility_policy_version"] ==
             expected["compatibility_policy_version"]

    assert schema_capability["identity_policy_version"] ==
             expected["identity_policy_version"]

    for contract <- expected["required_artifact_contracts"] do
      assert contract in schema_capability["artifact_contracts"]
    end
  end

  defp validate_inputs!(index) do
    for workflow <- index["workflows"], input <- workflow["inputs"] do
      path = input["path"]
      assert File.regular?(path), "missing workflow input #{path}"

      source = path |> File.read!() |> :json.decode()
      assert source["schema_version"] == input["schema_version"]

      case input["role"] do
        "study_manifest" ->
          assert %{
                   "status" => "pass",
                   "manifest_schema_contract" => input_contract
                 } = Manifest.validation_report(path)

          assert input_contract == input["validation_contract"]

        "campaign_request" ->
          assert source["request_type"] == input["request_type"]

          assert %{"status" => "pass", "type" => campaign_type} =
                   OrbitalDynamics.campaign_request_validation_report(
                     workflow["campaign_type"],
                     path
                   )

          assert campaign_type == workflow["campaign_type"]

          source_plan = Enum.find(workflow["inputs"], &(&1["role"] == "source_plan"))
          assert source["source_plan_ref"]["path"] == source_plan["path"]
          assert source["source_plan_ref"]["artifact_key"] == source_plan["artifact_key"]

        "source_plan" ->
          artifact = Map.fetch!(source, input["artifact_key"])

          assert {:ok,
                  %{
                    "schema_contract" => input_contract,
                    "schema_version" => input_version,
                    "status" => "pass"
                  }} = Schema.validate_artifact(artifact, contract: input["validation_contract"])

          assert input_contract == input["validation_contract"]
          assert input_version == input["schema_version"]
      end
    end
  end

  defp assert_broken_pinned_source_path!(index, tmp_root) do
    workflow = Enum.find(index["workflows"], &(&1["id"] == "v2_campaign_repair"))
    request_input = Enum.find(workflow["inputs"], &(&1["role"] == "campaign_request"))
    source_input = Enum.find(workflow["inputs"], &(&1["role"] == "source_plan"))
    failure = workflow["failure"]

    broken_source_path = source_input["path"] <> ".missing"
    broken_request_path = Path.join(tmp_root, "broken_v2_request.json")
    broken_output_path = Path.join(tmp_root, "broken_v2_output.json")

    broken_request =
      request_input["path"]
      |> File.read!()
      |> :json.decode()
      |> put_in(["source_plan_ref", "path"], broken_source_path)

    File.write!(broken_request_path, :json.encode(broken_request))

    request_path = request_input["path"]
    expected_output_path = materialize_path(workflow["output"], tmp_root)

    argv =
      workflow["argv"]
      |> materialize_paths(tmp_root)
      |> Enum.map(fn arg ->
        cond do
          arg == request_path -> broken_request_path
          arg == expected_output_path -> broken_output_path
          true -> arg
        end
      end)

    Mix.Task.reenable(workflow["task"])

    output =
      capture_io(fn ->
        error = assert_raise Mix.Error, fn -> Mix.Task.run(workflow["task"], argv) end
        assert Exception.message(error) =~ failure["exception"]
      end)

    assert output =~ failure["diagnostic"]
    assert failure["remediation"] =~ source_input["path"]
    assert failure["remediation"] =~ "orbital_dynamics.campaign.lint"
    refute File.exists?(broken_output_path)
  end

  defp assert_index_assertions!(value, assertions) do
    for assertion <- assertions do
      assert get_in(value, assertion["path"]) == assertion["value"]
    end
  end

  defp create_owned_tmp_root!(preferred_candidates \\ []) do
    do_create_owned_tmp_root!(preferred_candidates, @tmp_creation_attempts)
  end

  defp do_create_owned_tmp_root!(_preferred_candidates, 0) do
    raise "unable to create an exclusive Level 5 workflow temp root"
  end

  defp do_create_owned_tmp_root!(preferred_candidates, attempts_remaining) do
    {candidate, remaining_candidates} =
      case preferred_candidates do
        [candidate | rest] -> {candidate, rest}
        [] -> {random_tmp_candidate(), []}
      end

    candidate = validate_tmp_candidate!(candidate)

    case File.mkdir(candidate) do
      :ok ->
        ownership_token = random_token()
        marker_path = Path.join(candidate, @ownership_marker)

        case File.write(marker_path, ownership_token, [:exclusive]) do
          :ok ->
            {candidate, ownership_token}

          {:error, reason} ->
            File.rmdir(candidate)

            raise File.Error,
              reason: reason,
              action: "write Level 5 workflow ownership marker",
              path: marker_path
        end

      {:error, :eexist} ->
        do_create_owned_tmp_root!(remaining_candidates, attempts_remaining - 1)

      {:error, reason} ->
        raise File.Error,
          reason: reason,
          action: "create Level 5 workflow temp root",
          path: candidate
    end
  end

  defp cleanup_owned_tmp_root!(tmp_root, ownership_token) do
    expanded_root = validate_tmp_candidate!(tmp_root)
    marker_path = Path.join(expanded_root, @ownership_marker)

    unless File.regular?(marker_path) and File.read!(marker_path) == ownership_token do
      raise "refusing to remove unowned Level 5 workflow temp root #{expanded_root}"
    end

    File.rm_rf!(expanded_root)
    :ok
  end

  defp random_tmp_candidate do
    Path.join(System.tmp_dir!(), @tmp_prefix <> random_token())
  end

  defp random_token do
    24
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp validate_tmp_candidate!(candidate) do
    expanded_tmp_dir = Path.expand(System.tmp_dir!())
    expanded_candidate = Path.expand(candidate)

    unless Path.dirname(expanded_candidate) == expanded_tmp_dir and
             String.starts_with?(Path.basename(expanded_candidate), @tmp_prefix) do
      raise "unsafe Level 5 workflow temp-root candidate #{expanded_candidate}"
    end

    expanded_candidate
  end

  defp assert_direct_child!(file_path, tmp_root) do
    assert Path.dirname(Path.expand(file_path)) == Path.expand(tmp_root)
  end

  defp output_path_from_argv!(argv) do
    output_index = Enum.find_index(argv, &(&1 == "--output"))
    assert is_integer(output_index), "indexed support command is missing --output"

    output_path = Enum.at(argv, output_index + 1)
    assert is_binary(output_path), "indexed support command is missing an output path"
    output_path
  end

  defp json_roundtrip(value) do
    value
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> :json.decode()
  end

  defp materialize_paths(paths, tmp_root),
    do: Enum.map(paths, &materialize_path(&1, tmp_root))

  defp materialize_path(path, tmp_root),
    do: String.replace(path, @output_root, tmp_root)
end
