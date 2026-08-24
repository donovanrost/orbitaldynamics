defmodule OrbitalDynamics.CadenceImportConsumerConformanceTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.AuthorityContext
  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CadenceImport.Adapter
  alias OrbitalDynamics.CadenceImport.OuterAdmission
  alias OrbitalDynamics.Schema

  defmodule AdapterFixture do
    def capabilities do
      %{
        "contract" => "cadence_consumer_dry_run_adapter.v1",
        "operations" => ["dry_run"],
        "writes" => false
      }
    end

    def acknowledgement(request) do
      %{
        "status" => "conformant",
        "source_identity" => request["source_identity"],
        "authority_evidence" => request["authority_evidence"],
        "manifest_semantic_sha256" => request["manifest_semantic_sha256"],
        "idempotency_identity" => request["idempotency_identity"]
      }
    end

    def notify(message) do
      case Process.whereis(OrbitalDynamics.CadenceImportConsumerConformanceTest) do
        nil -> :ok
        observer -> send(observer, message)
      end
    end
  end

  defmodule InMemoryFakeAdapter do
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
      send(self(), {:cadence_consumer_dry_run, request, opts})

      case opts["mode"] do
        "adapter_error" ->
          {:error, %{"code" => "in_memory_adapter_rejected"}}

        "exception" ->
          raise "in-memory dry-run exception"

        "invalid_return" ->
          :invalid_return

        "identity_tamper" ->
          {:ok,
           request
           |> acknowledgement()
           |> put_in(["source_identity", "source_artifact_id"], "strategy:tampered")}

        "authority_tamper" ->
          {:ok, Map.put(acknowledgement(request), "authority_evidence", %{})}

        "idempotency_tamper" ->
          {:ok,
           Map.put(
             acknowledgement(request),
             "idempotency_identity",
             "cadence_consumer_dry_run:sha256:tampered"
           )}

        _mode ->
          {:ok, acknowledgement(request)}
      end
    end

    defp acknowledgement(request) do
      %{
        "status" => "conformant",
        "source_identity" => request["source_identity"],
        "authority_evidence" => request["authority_evidence"],
        "manifest_semantic_sha256" => request["manifest_semantic_sha256"],
        "idempotency_identity" => request["idempotency_identity"]
      }
    end
  end

  defmodule UnsupportedCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    @impl true
    def capabilities do
      %{
        "contract" => "cadence_consumer_dry_run_adapter.v1",
        "operations" => ["dry_run", "write"],
        "writes" => true
      }
    end

    @impl true
    def dry_run(_request, _opts), do: raise("must not delegate")
  end

  defmodule LifecycleAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.AdapterFixture

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      AdapterFixture.capabilities()
    end

    @impl true
    def dry_run(request, opts) do
      AdapterFixture.notify({:adapter_callback_started, :dry_run, self(), request, opts})

      case opts["mode"] do
        "never" ->
          receive do
            :release_test_adapter -> {:ok, AdapterFixture.acknowledgement(request)}
          end

        "trap_never" ->
          Process.flag(:trap_exit, true)
          AdapterFixture.notify({:adapter_callback_trapping, :dry_run, self()})
          trap_forever()

        "await_return" ->
          receive do
            :release_test_adapter ->
              AdapterFixture.notify({:adapter_callback_ready_to_return, self()})

              receive do
                :return_test_adapter -> {:ok, AdapterFixture.acknowledgement(request)}
              end
          end

        "sleep" ->
          Process.sleep(opts["sleep_ms"])
          {:ok, AdapterFixture.acknowledgement(request)}

        "exception" ->
          raise "bounded dry-run exception"

        "throw" ->
          throw(:bounded_dry_run_throw)

        "exit" ->
          exit(:bounded_dry_run_exit)

        "death" ->
          Process.exit(self(), :kill)

        _mode ->
          {:ok, AdapterFixture.acknowledgement(request)}
      end
    end

    defp trap_forever do
      receive do
        _message -> trap_forever()
      end
    end
  end

  defmodule NeverReturningCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})

      receive do
        :release_test_adapter -> AdapterFixture.capabilities()
      end
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter
  end

  defmodule TrappingCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      Process.flag(:trap_exit, true)
      AdapterFixture.notify({:adapter_callback_trapping, :capabilities, self()})
      trap_forever()
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter

    defp trap_forever do
      receive do
        _message -> trap_forever()
      end
    end
  end

  defmodule SilentTrappingCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.LifecycleAdapter

    @impl true
    def capabilities do
      Process.flag(:trap_exit, true)
      trap_forever()
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter

    defp trap_forever do
      receive do
        _message -> trap_forever()
      end
    end
  end

  defmodule SlowCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      Process.sleep(200)
      AdapterFixture.capabilities()
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter
  end

  defmodule ExceptionCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      raise "bounded capabilities exception"
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter
  end

  defmodule ThrowingCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      throw(:bounded_capabilities_throw)
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter
  end

  defmodule ExitingCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      exit(:bounded_capabilities_exit)
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter
  end

  defmodule DyingCapabilitiesAdapter do
    @behaviour OrbitalDynamics.CadenceImport.Adapter

    alias OrbitalDynamics.CadenceImportConsumerConformanceTest.{
      AdapterFixture,
      LifecycleAdapter
    }

    @impl true
    def capabilities do
      AdapterFixture.notify({:adapter_callback_started, :capabilities, self()})
      Process.exit(self(), :kill)
    end

    @impl true
    defdelegate dry_run(request, opts), to: LifecycleAdapter
  end

  setup do
    true = Process.register(self(), __MODULE__)
    :ok
  end

  test "declares the exact no-write adapter and public conformance capability surfaces" do
    assert Adapter.behaviour_info(:callbacks) |> Enum.sort() ==
             [capabilities: 0, dry_run: 2]

    assert InMemoryFakeAdapter.capabilities() == %{
             "contract" => "cadence_consumer_dry_run_adapter.v1",
             "operations" => ["dry_run"],
             "writes" => false
           }

    refute function_exported?(InMemoryFakeAdapter, :create, 1)
    refute function_exported?(InMemoryFakeAdapter, :update, 2)
    refute function_exported?(InMemoryFakeAdapter, :write, 2)
    refute function_exported?(InMemoryFakeAdapter, :mutate, 2)

    assert %{
             model: :explicit_adapter_dry_run_only,
             adapter_contract: "cadence_consumer_dry_run_adapter.v1",
             operations: ["dry_run"],
             writes: false,
             supported_sources: ["campaign_strategy.v3", "cadence_import_manifest.v1"],
             result_type: "cadence_consumer_conformance.v1",
             idempotency: :deterministic_semantic_request_identity,
             max_adapter_options: 2_048,
             execution_modes: [
               :synchronous_trusted_adapter,
               :bounded_monitored_callback_lifecycle
             ],
             bounded_callback_lifecycle: %{
               api: :bounded_dry_run_4,
               timeout_option: :timeout,
               deadline: :single_monotonic_deadline,
               callback_phases: [:capabilities, :dry_run],
               timed_out_worker: :killed_and_drained
             },
             outer_admission: %{
               "max_external_size_bytes" => 67_108_864,
               "max_top_level_fields" => 64,
               "max_campaign_branches" => 64,
               "max_manifest_rows" => 4_096,
               "max_operator_review_rows" => 4_096,
               "max_score_term_rows" => 4_096,
               "max_segment_map_fields" => 2_048,
               "max_validation_work_items" => 16_384
             }
           } = CadenceImport.capabilities().consumer_conformance
  end

  test "dry-runs the canonical current V3 artifact and its direct manifest identically" do
    strategy = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")
    manifest = strategy["cadence_import_manifest"]

    assert {:ok, result} = CadenceImport.dry_run(strategy, InMemoryFakeAdapter)
    assert_receive {:cadence_consumer_dry_run, request, %{}}

    assert {:ok, direct_result} = CadenceImport.dry_run(manifest, InMemoryFakeAdapter)
    assert_receive {:cadence_consumer_dry_run, direct_request, %{}}

    assert request["manifest"] == manifest
    assert direct_request == request
    assert direct_result == result

    assert request["source_identity"] == %{
             "source_artifact_type" => "campaign_strategy.v3",
             "source_artifact_id" => get_in(strategy, ["strategy_metadata", "strategy_id"]),
             "manifest_id" => manifest["manifest_id"]
           }

    assert request["authority_evidence"] == %{}
    assert result["type"] == "cadence_consumer_conformance.v1"
    assert result["status"] == "conformant"
    assert result["source_identity"] == request["source_identity"]
    assert result["authority_evidence"] == request["authority_evidence"]
    assert result["manifest_evidence"]["row_count"] == manifest["row_count"]
    assert result["conformance"]["writes_permitted"] == false
  end

  test "rejects valid-looking full-artifact manifest source ID and type rebinds" do
    strategy = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")
    manifest = strategy["cadence_import_manifest"]
    rebound_source_id = "strategy:rebound"

    source_id_rebound =
      manifest
      |> Map.put("source_artifact_id", rebound_source_id)
      |> Map.put("manifest_id", "cadence_import_manifest:#{rebound_source_id}")
      |> put_in(["provenance", "source_artifact_id"], rebound_source_id)

    source_type_rebound =
      manifest
      |> Map.put("source_artifact_type", "campaign_repair.v2")
      |> put_in(["provenance", "source_artifact_type"], "campaign_repair.v2")

    for rebound_manifest <- [source_id_rebound, source_type_rebound] do
      assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
               Schema.validate_artifact(rebound_manifest)

      rebound_strategy = Map.put(strategy, "cadence_import_manifest", rebound_manifest)

      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => "source_identity_tampered"
              }} = CadenceImport.dry_run(rebound_strategy, InMemoryFakeAdapter)
    end

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "preserves direct-manifest identity and immutable authority evidence deterministically" do
    manifest = valid_manifest_with_authority()
    opts = [scenario: "nominal"]

    assert {:ok, left} = CadenceImport.dry_run(manifest, InMemoryFakeAdapter, opts)
    assert_receive {:cadence_consumer_dry_run, left_request, %{"scenario" => "nominal"}}

    assert {:ok, right} = CadenceImport.dry_run(manifest, InMemoryFakeAdapter, opts)
    assert_receive {:cadence_consumer_dry_run, right_request, %{"scenario" => "nominal"}}

    authority_evidence =
      Map.take(
        manifest,
        ~w(eligibility_status authority_context authority_context_evaluation)
      )

    assert left == right
    assert left_request == right_request
    assert left_request["authority_evidence"] == authority_evidence
    assert left["authority_evidence"] == authority_evidence

    assert left["idempotency"]["identity"] == left_request["idempotency_identity"]
    assert byte_size(left["idempotency"]["semantic_output_sha256"]) == 64
    assert byte_size(left["manifest_evidence"]["semantic_sha256"]) == 64
  end

  test "rejects source identity and authority tampering before delegation" do
    manifest = valid_manifest_with_authority()

    identity_tampered =
      put_in(manifest, ["provenance", "source_artifact_id"], "strategy:other")

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "source_identity_tampered"
            }} = CadenceImport.dry_run(identity_tampered, InMemoryFakeAdapter)

    authority_tampered =
      put_in(
        manifest,
        ["authority_context_evaluation", "reason"],
        "tampered after evaluation"
      )

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "authority_evidence_tampered"
            }} = CadenceImport.dry_run(authority_tampered, InMemoryFakeAdapter)

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "rejects every reproduced unsafe additive V3 field before delegation" do
    strategy = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")

    unsafe_values = [
      self(),
      fn -> :not_json end,
      make_ref(),
      <<1::1>>,
      <<255>>,
      [1 | :improper_tail],
      List.duplicate(0, 2_049)
    ]

    for unsafe <- unsafe_values do
      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => "unsafe_outer_input"
              }} =
               strategy
               |> Map.put("unknown_outer_addition", unsafe)
               |> CadenceImport.dry_run(InMemoryFakeAdapter)
    end

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "admits the generic collection limit and rejects one item over before delegation" do
    strategy = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")

    at_limit = Map.put(strategy, "unknown_outer_addition", List.duplicate(0, 2_048))

    assert {:ok, %{"status" => "conformant"}} =
             CadenceImport.dry_run(at_limit, InMemoryFakeAdapter)

    assert_receive {:cadence_consumer_dry_run,
                    %{"manifest" => %{"schema_contract" => "cadence_import_manifest.v1"}}, %{}}

    over_limit = Map.put(strategy, "unknown_outer_addition", List.duplicate(0, 2_049))

    assert {:error, over_error} = CadenceImport.dry_run(over_limit, InMemoryFakeAdapter)
    assert over_error["code"] == "unsafe_outer_input"
    assert over_error == elem(CadenceImport.dry_run(over_limit, InMemoryFakeAdapter), 1)

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "enforces deterministic top-level row and total-work admission boundaries" do
    limits = OuterAdmission.limits()

    at_top_level_limit =
      Map.new(1..limits["max_top_level_fields"], fn index ->
        {"field_#{index}", :null}
      end)

    assert :ok = OuterAdmission.validate(at_top_level_limit)

    over_top_level_limit = Map.put(at_top_level_limit, "field_over_limit", :null)
    assert {:error, top_error} = OuterAdmission.validate(over_top_level_limit)
    assert top_error["details"]["max_field_count"] == limits["max_top_level_fields"]
    assert {:error, ^top_error} = OuterAdmission.validate(over_top_level_limit)

    at_row_limit = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "rows" => List.duplicate(%{}, limits["max_manifest_rows"])
    }

    assert :ok = OuterAdmission.validate(at_row_limit)

    over_row_limit =
      Map.put(at_row_limit, "rows", List.duplicate(%{}, limits["max_manifest_rows"] + 1))

    assert {:error, row_error} = OuterAdmission.validate(over_row_limit)
    assert row_error["details"]["max_item_count"] == limits["max_manifest_rows"]
    assert {:error, ^row_error} = OuterAdmission.validate(over_row_limit)

    at_work_limit = validation_work_boundary_input(59)
    assert :ok = OuterAdmission.validate(at_work_limit)

    over_work_limit = validation_work_boundary_input(60)
    assert {:error, work_error} = OuterAdmission.validate(over_work_limit)
    assert work_error["details"]["actual_validation_work_items"] == 16_385
    assert work_error["details"]["max_validation_work_items"] == 16_384
    assert {:error, ^work_error} = OuterAdmission.validate(over_work_limit)
  end

  test "enforces the fixed external-size boundary exactly" do
    max_external_size = OuterAdmission.limits()["max_external_size_bytes"]
    at_limit = external_size_boundary_input(max_external_size)

    assert :erlang.external_size(at_limit) == max_external_size
    assert :ok = OuterAdmission.validate(at_limit)

    over_limit = update_in(at_limit, ["branches", Access.at(0), "padding"], &(&1 <> <<0>>))

    assert :erlang.external_size(over_limit) == max_external_size + 1
    assert {:error, size_error} = OuterAdmission.validate(over_limit)
    assert size_error["details"]["actual_external_size_bytes"] == max_external_size + 1
    assert size_error["details"]["max_external_size_bytes"] == max_external_size
    assert {:error, ^size_error} = OuterAdmission.validate(over_limit)
  end

  test "rejects structurally over-limit terms before outer-size admission" do
    shared_payload = :binary.copy(<<0>>, 1_100_000)

    oversized_top_level =
      1..64
      |> Map.new(fn index -> {"unknown_field_#{index}", shared_payload} end)
      |> Map.put("schema_contract", "campaign_strategy.v3")

    oversized_branches = %{
      "schema_contract" => "campaign_strategy.v3",
      "branches" => List.duplicate(%{"padding" => shared_payload}, 65)
    }

    max_external_size = OuterAdmission.limits()["max_external_size_bytes"]

    assert map_size(oversized_top_level) == 65
    assert :erlang.external_size(oversized_top_level) > max_external_size
    assert :erlang.external_size(oversized_branches) > max_external_size

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "unsafe_outer_input",
              "details" => %{
                "actual_field_count" => 65,
                "max_field_count" => 64,
                "path" => "$"
              }
            }} = CadenceImport.dry_run(oversized_top_level, InMemoryFakeAdapter)

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "unsafe_outer_input",
              "details" => %{
                "actual_item_count_at_least" => 65,
                "max_item_count" => 64,
                "path" => "$.branches"
              }
            }} = CadenceImport.dry_run(oversized_branches, InMemoryFakeAdapter)

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "contains malformed unsupported and malicious outer inputs as typed errors" do
    manifest = valid_manifest_with_authority()

    for {input, expected_code} <- [
          {self(), "invalid_outer_input"},
          {%URI{scheme: "cadence"}, "invalid_outer_input"},
          {%{"schema_contract" => "campaign_plan.v1"}, "unsupported_input"},
          {%{"schema_contract" => "cadence_import_manifest.v1"}, "invalid_artifact"}
        ] do
      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => ^expected_code
              }} = CadenceImport.dry_run(input, InMemoryFakeAdapter)
    end

    unsafe = Map.put(manifest, "ambient_process", self())

    assert {:error, %{"code" => "unsafe_outer_input"}} =
             CadenceImport.dry_run(unsafe, InMemoryFakeAdapter)

    assert {:error, %{"code" => "invalid_options"}} =
             CadenceImport.dry_run(manifest, InMemoryFakeAdapter, caller: self())

    assert {:error, %{"code" => "invalid_options"}} =
             CadenceImport.dry_run(manifest, InMemoryFakeAdapter,
               scenario: "left",
               scenario: "right"
             )

    assert {:error,
            %{
              "code" => "invalid_options",
              "details" => %{"invalid_item_position" => 1}
            }} = CadenceImport.dry_run(manifest, InMemoryFakeAdapter, [{"scenario", "nominal"}])

    assert {:error,
            %{
              "code" => "invalid_options",
              "details" => %{"validated_item_count" => 1}
            }} =
             CadenceImport.dry_run(
               manifest,
               InMemoryFakeAdapter,
               [{:scenario, "nominal"} | :improper_tail]
             )

    assert {:error, %{"code" => "invalid_adapter"}} =
             CadenceImport.dry_run(manifest, "Elixir.DynamicAdapter")

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "halts promptly on a duplicate near the head of a large proper option list" do
    large_options =
      [{:scenario, "first"} | List.duplicate({:scenario, "duplicate"}, 250_000)]

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "invalid_options",
              "details" => %{
                "duplicate_key" => "scenario",
                "examined_item_count" => 2
              }
            }} =
             CadenceImport.dry_run(
               valid_manifest_with_authority(),
               InMemoryFakeAdapter,
               large_options
             )

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "accepts exactly 2048 option entries and rejects item 2049" do
    option_keys = existing_option_key_atoms()
    assert length(option_keys) >= 2_049

    at_limit =
      option_keys
      |> Enum.take(2_048)
      |> Enum.with_index()
      |> Enum.map(fn {key, index} -> {key, index} end)

    assert {:ok, %{"status" => "conformant"}} =
             CadenceImport.dry_run(valid_manifest_with_authority(), InMemoryFakeAdapter, at_limit)

    assert_receive {:cadence_consumer_dry_run, _request, normalized_options}
    assert map_size(normalized_options) == 2_048

    over_limit = at_limit ++ [{Enum.at(option_keys, 2_048), 2_048}]

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "invalid_options",
              "details" => %{
                "actual_item_count_at_least" => 2_049,
                "max_item_count" => 2_048
              }
            }} =
             CadenceImport.dry_run(
               valid_manifest_with_authority(),
               InMemoryFakeAdapter,
               over_limit
             )

    refute_receive {:cadence_consumer_dry_run, _request, _opts}
  end

  test "rejects unsupported adapter capabilities without invoking dry_run" do
    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "unsupported_adapter_capabilities",
              "details" => %{
                "required" => %{
                  "contract" => "cadence_consumer_dry_run_adapter.v1",
                  "operations" => ["dry_run"],
                  "writes" => false
                }
              }
            }} =
             CadenceImport.dry_run(
               valid_manifest_with_authority(),
               UnsupportedCapabilitiesAdapter
             )
  end

  test "contains adapter errors exceptions invalid returns and acknowledgement tampering" do
    manifest = valid_manifest_with_authority()

    for {mode, expected_code} <- [
          {"adapter_error", "adapter_error"},
          {"exception", "adapter_exception"},
          {"invalid_return", "invalid_adapter_return"},
          {"identity_tamper", "adapter_identity_tampered"},
          {"authority_tamper", "adapter_authority_tampered"},
          {"idempotency_tamper", "adapter_idempotency_tampered"}
        ] do
      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => ^expected_code
              }} = CadenceImport.dry_run(manifest, InMemoryFakeAdapter, mode: mode)

      assert_receive {:cadence_consumer_dry_run, _request, %{"mode" => ^mode}}
    end
  end

  test "bounded and synchronous success preserve identical semantic request and result identity" do
    manifest = valid_manifest_with_authority()
    adapter_opts = [scenario: "nominal"]

    assert {:ok, synchronous_result} =
             CadenceImport.dry_run(manifest, LifecycleAdapter, adapter_opts)

    assert_receive {:adapter_callback_started, :capabilities, synchronous_capabilities_pid}

    assert_receive {:adapter_callback_started, :dry_run, synchronous_dry_run_pid,
                    synchronous_request, %{"scenario" => "nominal"}}

    assert synchronous_capabilities_pid == self()
    assert synchronous_dry_run_pid == self()

    assert {:ok, bounded_result} =
             CadenceImport.bounded_dry_run(
               manifest,
               LifecycleAdapter,
               adapter_opts,
               timeout: 500
             )

    assert_receive {:adapter_callback_started, :capabilities, bounded_capabilities_pid}

    assert_receive {:adapter_callback_started, :dry_run, bounded_dry_run_pid, bounded_request,
                    %{"scenario" => "nominal"}}

    refute bounded_capabilities_pid == self()
    refute bounded_dry_run_pid == self()
    refute bounded_capabilities_pid == bounded_dry_run_pid
    assert_process_dead(bounded_capabilities_pid)
    assert_process_dead(bounded_dry_run_pid)

    assert bounded_request == synchronous_request
    assert bounded_result == synchronous_result
    assert bounded_result["source_identity"] == synchronous_request["source_identity"]
    assert bounded_result["authority_evidence"] == synchronous_request["authority_evidence"]

    assert bounded_result["idempotency"]["identity"] ==
             synchronous_request["idempotency_identity"]
  end

  test "validates one finite positive timeout before any adapter delegation" do
    manifest = valid_manifest_with_authority()

    invalid_lifecycle_options = [
      [],
      [timeout: 0],
      [timeout: -1],
      [timeout: 1.0],
      [timeout: :infinity],
      [timeout: 10, timeout: 20],
      [timeout: 10, unsupported: true],
      [unsupported: 10],
      [{"timeout", 10}],
      [{:timeout, 10} | :improper_tail]
    ]

    for lifecycle_opts <- invalid_lifecycle_options do
      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => "invalid_timeout_options"
              }} =
               CadenceImport.bounded_dry_run(
                 manifest,
                 LifecycleAdapter,
                 [],
                 lifecycle_opts
               )
    end

    assert {:error,
            %{
              "code" => "invalid_timeout_options",
              "details" => %{
                "duplicate_key" => "timeout",
                "examined_item_count" => 2
              }
            }} =
             CadenceImport.bounded_dry_run(
               manifest,
               LifecycleAdapter,
               [],
               timeout: 10,
               timeout: 20
             )

    refute_receive {:adapter_callback_started, _phase, _worker}
    refute_receive {:adapter_callback_started, _phase, _worker, _request, _opts}
  end

  test "times out and cancellation kill trapping capabilities lifecycle processes cleanly" do
    sentinel = make_ref()
    send(self(), {:unrelated_mailbox_message, sentinel})

    assert {:error,
            %{
              "type" => "cadence_consumer_conformance_error.v1",
              "code" => "adapter_capabilities_timeout",
              "details" => %{"phase" => "capabilities", "timeout_ms" => 30}
            }} =
             CadenceImport.bounded_dry_run(
               valid_manifest_with_authority(),
               NeverReturningCapabilitiesAdapter,
               [],
               timeout: 30
             )

    assert_receive {:unrelated_mailbox_message, ^sentinel}
    assert_receive {:adapter_callback_started, :capabilities, worker}
    refute Process.alive?(worker)
    assert Process.alive?(self())

    refute_receive {{OrbitalDynamics.CadenceImport.ConsumerConformance, :bounded_callback, _ref},
                    _outcome},
                   20

    refute_receive {:DOWN, _ref, :process, ^worker, _reason}, 20

    baseline_monitors = observer_monitors()
    baseline_messages = observer_messages()

    {caller, caller_ref, call_tag} =
      spawn_bounded_call(
        valid_manifest_with_authority(),
        TrappingCapabilitiesAdapter,
        [],
        timeout: 5_000
      )

    assert_receive {:adapter_callback_started, :capabilities, trapping_worker}
    assert_receive {:adapter_callback_trapping, :capabilities, ^trapping_worker}
    {controller, guardian} = lifecycle_owners(trapping_worker)

    Process.exit(caller, :kill)
    assert_receive {:DOWN, ^caller_ref, :process, ^caller, :killed}

    assert_process_dead(trapping_worker)
    assert_process_dead(controller)
    assert_process_dead(guardian)
    refute_receive {:bounded_caller_result, ^call_tag, ^caller, _result}, 30
    assert observer_monitors() == baseline_monitors
    assert observer_messages() == baseline_messages
    assert_no_lifecycle_messages([caller, trapping_worker, controller, guardian])
  end

  test "uses one deadline and cancellation contains trapping dry_run without accumulation" do
    started = System.monotonic_time(:millisecond)

    assert {:error,
            %{
              "code" => "adapter_dry_run_timeout",
              "details" => %{"phase" => "dry_run", "timeout_ms" => 400}
            }} =
             CadenceImport.bounded_dry_run(
               valid_manifest_with_authority(),
               SlowCapabilitiesAdapter,
               [mode: "never"],
               timeout: 400
             )

    elapsed = System.monotonic_time(:millisecond) - started

    assert_receive {:adapter_callback_started, :capabilities, capabilities_worker}

    assert_receive {:adapter_callback_started, :dry_run, dry_run_worker, _request,
                    %{"mode" => "never"}}

    assert_process_dead(capabilities_worker)
    refute Process.alive?(dry_run_worker)
    assert elapsed < 550
    assert Process.alive?(self())

    baseline_monitors = observer_monitors()
    baseline_messages = observer_messages()
    baseline_roles = lifecycle_role_pids()

    {caller, caller_ref, call_tag} =
      spawn_bounded_call(
        valid_manifest_with_authority(),
        LifecycleAdapter,
        [mode: "trap_never"],
        timeout: 5_000
      )

    assert_receive {:adapter_callback_started, :capabilities, cancellation_capabilities_worker}

    assert_receive {:adapter_callback_started, :dry_run, trapping_worker, _request,
                    %{"mode" => "trap_never"}}

    assert_receive {:adapter_callback_trapping, :dry_run, ^trapping_worker}
    {controller, guardian} = lifecycle_owners(trapping_worker)

    Process.exit(caller, :kill)
    assert_receive {:DOWN, ^caller_ref, :process, ^caller, :killed}

    assert_process_dead(cancellation_capabilities_worker)
    assert_process_dead(trapping_worker)
    assert_process_dead(controller)
    assert_process_dead(guardian)
    refute_receive {:bounded_caller_result, ^call_tag, ^caller, _result}, 30
    assert observer_monitors() == baseline_monitors

    cancelled_processes =
      for iteration <- 1..8, reduce: [] do
        processes ->
          {adapter, options, phase} =
            if rem(iteration, 2) == 0 do
              {TrappingCapabilitiesAdapter, [], :capabilities}
            else
              {LifecycleAdapter, [mode: "trap_never"], :dry_run}
            end

          processes ++ cancel_trapping_call(adapter, options, phase)
      end

    assert_role_processes_restored(baseline_roles)
    assert observer_monitors() == baseline_monitors
    assert observer_messages() == baseline_messages
    assert_no_lifecycle_messages(cancelled_processes)
  end

  test "rejects an acknowledgement racing at the deadline and cannot reuse it later" do
    manifest = valid_manifest_with_authority()

    assert {:error, %{"code" => "adapter_dry_run_timeout"}} =
             CadenceImport.bounded_dry_run(
               manifest,
               LifecycleAdapter,
               [mode: "sleep", sleep_ms: 30],
               timeout: 30
             )

    assert_receive {:adapter_callback_started, :capabilities, first_capabilities_worker}

    assert_receive {:adapter_callback_started, :dry_run, first_dry_run_worker, _request,
                    %{"mode" => "sleep", "sleep_ms" => 30}}

    assert_process_dead(first_capabilities_worker)
    refute Process.alive?(first_dry_run_worker)

    assert {:ok, retry_result} =
             CadenceImport.bounded_dry_run(manifest, LifecycleAdapter, [], timeout: 500)

    assert_receive {:adapter_callback_started, :capabilities, retry_capabilities_worker}

    assert_receive {:adapter_callback_started, :dry_run, retry_dry_run_worker, retry_request, %{}}

    assert retry_result["idempotency"]["identity"] == retry_request["idempotency_identity"]
    assert_process_dead(retry_capabilities_worker)
    assert_process_dead(retry_dry_run_worker)

    refute_receive {{OrbitalDynamics.CadenceImport.ConsumerConformance, :bounded_callback, _ref},
                    _outcome},
                   50

    startup_role_baseline = lifecycle_role_pids()

    for _iteration <- 1..20 do
      assert {:error, %{"code" => "adapter_capabilities_timeout"}} =
               CadenceImport.bounded_dry_run(
                 manifest,
                 SilentTrappingCapabilitiesAdapter,
                 [],
                 timeout: 1
               )
    end

    assert_role_processes_restored(startup_role_baseline)

    baseline_monitors = observer_monitors()
    baseline_messages = observer_messages()

    {before_result_caller, before_result_ref, before_result_tag} =
      spawn_bounded_call(
        manifest,
        LifecycleAdapter,
        [mode: "await_return"],
        timeout: 5_000
      )

    assert_receive {:adapter_callback_started, :capabilities, before_result_capabilities}

    assert_receive {:adapter_callback_started, :dry_run, before_result_worker, _request,
                    %{"mode" => "await_return"}}

    {before_result_controller, before_result_guardian} =
      lifecycle_owners(before_result_worker)

    send(before_result_worker, :release_test_adapter)
    assert_receive {:adapter_callback_ready_to_return, ^before_result_worker}
    Process.exit(before_result_caller, :kill)
    send(before_result_worker, :return_test_adapter)

    assert_receive {:DOWN, ^before_result_ref, :process, ^before_result_caller, :killed}
    assert_process_dead(before_result_capabilities)
    assert_process_dead(before_result_worker)
    assert_process_dead(before_result_controller)
    assert_process_dead(before_result_guardian)

    refute_receive {:bounded_caller_result, ^before_result_tag, ^before_result_caller, _result},
                   30

    {after_result_caller, after_result_ref, after_result_tag} =
      spawn_bounded_call(
        manifest,
        LifecycleAdapter,
        [mode: "await_return"],
        timeout: 500
      )

    assert_receive {:adapter_callback_started, :capabilities, after_result_capabilities}

    assert_receive {:adapter_callback_started, :dry_run, after_result_worker, _request,
                    %{"mode" => "await_return"}}

    {after_result_controller, after_result_guardian} = lifecycle_owners(after_result_worker)
    send(after_result_worker, :release_test_adapter)
    assert_receive {:adapter_callback_ready_to_return, ^after_result_worker}
    send(after_result_worker, :return_test_adapter)

    assert_receive {:bounded_caller_result, ^after_result_tag, ^after_result_caller,
                    {:ok, _result}}

    assert_process_dead(after_result_capabilities)
    assert_process_dead(after_result_worker)
    assert_process_dead(after_result_controller)
    assert_process_dead(after_result_guardian)
    Process.exit(after_result_caller, :kill)
    assert_receive {:DOWN, ^after_result_ref, :process, ^after_result_caller, :killed}

    {before_deadline_caller, before_deadline_ref, before_deadline_tag} =
      spawn_bounded_call(
        manifest,
        LifecycleAdapter,
        [mode: "trap_never"],
        timeout: 200
      )

    assert_receive {:adapter_callback_started, :capabilities, before_deadline_capabilities}

    assert_receive {:adapter_callback_started, :dry_run, before_deadline_worker, _request,
                    %{"mode" => "trap_never"}}

    assert_receive {:adapter_callback_trapping, :dry_run, ^before_deadline_worker}

    {before_deadline_controller, before_deadline_guardian} =
      lifecycle_owners(before_deadline_worker)

    Process.sleep(150)
    Process.exit(before_deadline_caller, :kill)

    assert_receive {:DOWN, ^before_deadline_ref, :process, ^before_deadline_caller, :killed}
    assert_process_dead(before_deadline_capabilities)
    assert_process_dead(before_deadline_worker)
    assert_process_dead(before_deadline_controller)
    assert_process_dead(before_deadline_guardian)

    refute_receive {:bounded_caller_result, ^before_deadline_tag, ^before_deadline_caller,
                    _result},
                   30

    {after_deadline_caller, after_deadline_ref, after_deadline_tag} =
      spawn_bounded_call(
        manifest,
        LifecycleAdapter,
        [mode: "trap_never"],
        timeout: 30
      )

    assert_receive {:adapter_callback_started, :capabilities, after_deadline_capabilities}

    assert_receive {:adapter_callback_started, :dry_run, after_deadline_worker, _request,
                    %{"mode" => "trap_never"}}

    assert_receive {:adapter_callback_trapping, :dry_run, ^after_deadline_worker}
    {after_deadline_controller, after_deadline_guardian} = lifecycle_owners(after_deadline_worker)

    assert_receive {:bounded_caller_result, ^after_deadline_tag, ^after_deadline_caller,
                    {:error, %{"code" => "adapter_dry_run_timeout"}}}

    assert_process_dead(after_deadline_capabilities)
    assert_process_dead(after_deadline_worker)
    assert_process_dead(after_deadline_controller)
    assert_process_dead(after_deadline_guardian)
    Process.exit(after_deadline_caller, :kill)
    assert_receive {:DOWN, ^after_deadline_ref, :process, ^after_deadline_caller, :killed}

    assert observer_monitors() == baseline_monitors
    assert observer_messages() == baseline_messages

    assert_no_lifecycle_messages([
      before_result_caller,
      before_result_worker,
      before_result_controller,
      before_result_guardian,
      after_result_caller,
      after_result_worker,
      after_result_controller,
      after_result_guardian,
      before_deadline_caller,
      before_deadline_worker,
      before_deadline_controller,
      before_deadline_guardian,
      after_deadline_caller,
      after_deadline_worker,
      after_deadline_controller,
      after_deadline_guardian
    ])
  end

  test "contains capability exceptions throws exits and monitored worker death distinctly" do
    caller = self()
    manifest = valid_manifest_with_authority()

    for {adapter, expected_code} <- [
          {ExceptionCapabilitiesAdapter, "adapter_capabilities_exception"},
          {ThrowingCapabilitiesAdapter, "adapter_capabilities_throw"},
          {ExitingCapabilitiesAdapter, "adapter_capabilities_exit"},
          {DyingCapabilitiesAdapter, "adapter_capabilities_worker_death"}
        ] do
      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => ^expected_code
              }} =
               CadenceImport.bounded_dry_run(manifest, adapter, [], timeout: 500)

      assert_receive {:adapter_callback_started, :capabilities, worker}
      assert_process_dead(worker)
      assert self() == caller
      assert Process.alive?(caller)
    end

    baseline_monitors = observer_monitors()
    baseline_messages = observer_messages()

    {controlled_caller, controlled_caller_ref, call_tag} =
      spawn_bounded_call(manifest, TrappingCapabilitiesAdapter, [], timeout: 5_000)

    assert_receive {:adapter_callback_started, :capabilities, trapping_worker}
    assert_receive {:adapter_callback_trapping, :capabilities, ^trapping_worker}
    {controller, guardian} = lifecycle_owners(trapping_worker)

    Process.exit(controller, :kill)

    assert_receive {:bounded_caller_result, ^call_tag, ^controlled_caller,
                    {:error,
                     %{
                       "type" => "cadence_consumer_conformance_error.v1",
                       "code" => "adapter_capabilities_controller_death",
                       "details" => %{
                         "phase" => "capabilities",
                         "reason" => "killed"
                       }
                     }}}

    assert_process_dead(controller)
    assert_process_dead(trapping_worker)
    assert_process_dead(guardian)
    assert Process.alive?(controlled_caller)
    Process.exit(controlled_caller, :kill)

    assert_receive {:DOWN, ^controlled_caller_ref, :process, ^controlled_caller, :killed}
    assert observer_monitors() == baseline_monitors
    assert observer_messages() == baseline_messages
    assert_no_lifecycle_messages([controlled_caller, controller, trapping_worker, guardian])
  end

  test "contains dry_run exceptions throws exits and monitored worker death distinctly" do
    caller = self()
    manifest = valid_manifest_with_authority()

    for {mode, expected_code} <- [
          {"exception", "adapter_dry_run_exception"},
          {"throw", "adapter_dry_run_throw"},
          {"exit", "adapter_dry_run_exit"},
          {"death", "adapter_dry_run_worker_death"}
        ] do
      assert {:error,
              %{
                "type" => "cadence_consumer_conformance_error.v1",
                "code" => ^expected_code
              }} =
               CadenceImport.bounded_dry_run(
                 manifest,
                 LifecycleAdapter,
                 [mode: mode],
                 timeout: 500
               )

      assert_receive {:adapter_callback_started, :capabilities, capabilities_worker}

      assert_receive {:adapter_callback_started, :dry_run, dry_run_worker, _request,
                      %{"mode" => ^mode}}

      assert_process_dead(capabilities_worker)
      assert_process_dead(dry_run_worker)
      assert self() == caller
      assert Process.alive?(caller)
    end

    baseline_monitors = observer_monitors()
    baseline_messages = observer_messages()

    {controlled_caller, controlled_caller_ref, call_tag} =
      spawn_bounded_call(
        manifest,
        LifecycleAdapter,
        [mode: "trap_never"],
        timeout: 5_000
      )

    assert_receive {:adapter_callback_started, :capabilities, capabilities_worker}

    assert_receive {:adapter_callback_started, :dry_run, trapping_worker, _request,
                    %{"mode" => "trap_never"}}

    assert_receive {:adapter_callback_trapping, :dry_run, ^trapping_worker}
    {controller, guardian} = lifecycle_owners(trapping_worker)
    Process.exit(controller, :shutdown)

    assert_receive {:bounded_caller_result, ^call_tag, ^controlled_caller,
                    {:error,
                     %{
                       "type" => "cadence_consumer_conformance_error.v1",
                       "code" => "adapter_dry_run_controller_death",
                       "details" => %{
                         "phase" => "dry_run",
                         "reason" => "shutdown"
                       }
                     }}}

    assert_process_dead(capabilities_worker)
    assert_process_dead(controller)
    assert_process_dead(trapping_worker)
    assert_process_dead(guardian)
    assert Process.alive?(controlled_caller)
    Process.exit(controlled_caller, :kill)

    assert_receive {:DOWN, ^controlled_caller_ref, :process, ^controlled_caller, :killed}
    assert observer_monitors() == baseline_monitors
    assert observer_messages() == baseline_messages
    assert_no_lifecycle_messages([controlled_caller, controller, trapping_worker, guardian])
  end

  test "keeps synchronous trusted-adapter exception throw and exit errors byte-compatible" do
    manifest = valid_manifest_with_authority()

    for {mode, expected_error} <- [
          {"exception",
           %{
             "type" => "cadence_consumer_conformance_error.v1",
             "status" => "error",
             "code" => "adapter_exception",
             "message" => "adapter dry_run raised an exception",
             "details" => %{"exception" => "Elixir.RuntimeError"}
           }},
          {"throw",
           %{
             "type" => "cadence_consumer_conformance_error.v1",
             "status" => "error",
             "code" => "adapter_throw",
             "message" => "adapter dry_run did not return",
             "details" => %{}
           }},
          {"exit",
           %{
             "type" => "cadence_consumer_conformance_error.v1",
             "status" => "error",
             "code" => "adapter_exit",
             "message" => "adapter dry_run did not return",
             "details" => %{}
           }}
        ] do
      assert {:error, ^expected_error} =
               CadenceImport.dry_run(manifest, LifecycleAdapter, mode: mode)

      assert_receive {:adapter_callback_started, :capabilities, caller}
      assert caller == self()

      assert_receive {:adapter_callback_started, :dry_run, ^caller, _request, %{"mode" => ^mode}}
    end

    for {adapter, expected_error} <- [
          {ExceptionCapabilitiesAdapter,
           %{
             "type" => "cadence_consumer_conformance_error.v1",
             "status" => "error",
             "code" => "adapter_capabilities_exception",
             "message" => "adapter capabilities raised an exception",
             "details" => %{"exception" => "Elixir.RuntimeError"}
           }},
          {ThrowingCapabilitiesAdapter,
           %{
             "type" => "cadence_consumer_conformance_error.v1",
             "status" => "error",
             "code" => "adapter_capabilities_throw",
             "message" => "adapter capabilities did not return",
             "details" => %{}
           }},
          {ExitingCapabilitiesAdapter,
           %{
             "type" => "cadence_consumer_conformance_error.v1",
             "status" => "error",
             "code" => "adapter_capabilities_exit",
             "message" => "adapter capabilities did not return",
             "details" => %{}
           }}
        ] do
      assert {:error, ^expected_error} = CadenceImport.dry_run(manifest, adapter)
      assert_receive {:adapter_callback_started, :capabilities, caller}
      assert caller == self()
    end
  end

  test "bounded lifecycle adds no network or write API and does not mutate its input" do
    manifest = valid_manifest_with_authority()
    original_bytes = :erlang.term_to_binary(manifest, [:deterministic])

    assert Adapter.behaviour_info(:callbacks) |> Enum.sort() ==
             [capabilities: 0, dry_run: 2]

    for callback <- [:connect, :request, :create, :update, :write, :mutate, :approve, :execute] do
      refute function_exported?(LifecycleAdapter, callback, 2)
    end

    assert {:ok, %{"conformance" => %{"writes_permitted" => false}}} =
             CadenceImport.bounded_dry_run(
               manifest,
               LifecycleAdapter,
               [],
               timeout: 500
             )

    assert_receive {:adapter_callback_started, :capabilities, capabilities_worker}
    assert_receive {:adapter_callback_started, :dry_run, dry_run_worker, request, %{}}
    assert request["manifest"] == manifest
    assert_process_dead(capabilities_worker)
    assert_process_dead(dry_run_worker)
    assert :erlang.term_to_binary(manifest, [:deterministic]) == original_bytes

    limits = CadenceImport.capabilities().consumer_conformance.known_limits
    assert :bounded_lifecycle_is_not_a_malicious_code_sandbox in limits
    assert :bounded_lifecycle_does_not_guarantee_descendant_process_containment in limits
    assert :bounded_lifecycle_does_not_contain_adapter_side_effects in limits
    assert :does_not_supply_a_live_cadence_client in limits
    assert :does_not_establish_downstream_consumer_acceptance in limits
  end

  test "leaves the producer-only manifest and capability APIs unchanged" do
    manifest = valid_manifest_with_authority()

    assert CadenceImport.manifest(manifest) == manifest
    assert CadenceImport.capability().model == :artifact_only_cadence_import_manifest

    assert CadenceImport.capability().known_limits == [
             :does_not_write_cadence,
             :does_not_approve_operator_actions,
             :does_not_resolve_schedule_conflicts,
             :review_rows_are_adapter_handoff_not_operator_approval
           ]

    assert OrbitalDynamics.capability_catalog().operations.cadence_import ==
             CadenceImport.capabilities()
  end

  defp valid_manifest_with_authority do
    context =
      AuthorityContext.new!(%{
        "schema_contract" => "authority_context.v1",
        "authority_source" => "mission-operations-authority-registry",
        "source_revision" => "consumer-conformance-1",
        "effective_from" => "2026-08-20T00:00:00Z",
        "valid_until" => "2026-08-21T00:00:00Z",
        "evaluation_time" => "2026-08-20T12:00:00Z"
      })

    {:ok, ^context, evaluation} = AuthorityContext.evaluate("explicit", context)
    source_id = "strategy:consumer-conformance"

    manifest = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "schema_version" => 1,
      "model" => "artifact_only_cadence_import_manifest",
      "manifest_id" => "cadence_import_manifest:#{source_id}",
      "source_artifact_type" => "campaign_strategy.v3",
      "source_artifact_id" => source_id,
      "eligibility_status" => "eligible",
      "authority_context" => context,
      "authority_context_evaluation" => evaluation,
      "row_count" => 0,
      "ready_count" => 0,
      "review_required_count" => 0,
      "blocked_count" => 0,
      "missing_import_count" => 0,
      "rows" => [],
      "provenance" => %{
        "source" => "CadenceImportConsumerConformanceTest",
        "source_artifact_type" => "campaign_strategy.v3",
        "source_artifact_id" => source_id
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "row_source" => "empty_conformance_fixture",
        "deterministic_ordering" => "source_order"
      },
      "model_limits" => CadenceImport.capability().known_limits |> Enum.map(&Atom.to_string/1)
    }

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    manifest
  end

  defp validation_work_boundary_input(manifest_row_count) do
    repair_result =
      Map.new(1..253, fn index ->
        {"field_#{index}", :null}
      end)

    %{
      "schema_contract" => "campaign_strategy.v3",
      "branches" => List.duplicate(%{"repair_result" => repair_result}, 64),
      "cadence_import_manifest" => %{"rows" => List.duplicate(%{}, manifest_row_count)},
      "padding" => :null
    }
  end

  defp external_size_boundary_input(max_external_size) do
    branch_count = 16

    base = %{
      "schema_contract" => "campaign_strategy.v3",
      "branches" => List.duplicate(%{"padding" => <<>>}, branch_count)
    }

    payload_bytes = max_external_size - :erlang.external_size(base)
    bytes_per_branch = div(payload_bytes, branch_count)
    extra_bytes = rem(payload_bytes, branch_count)

    branches =
      for index <- 0..(branch_count - 1) do
        byte_count = bytes_per_branch + if(index < extra_bytes, do: 1, else: 0)
        %{"padding" => :binary.copy(<<0>>, byte_count)}
      end

    Map.put(base, "branches", branches)
  end

  defp existing_option_key_atoms do
    # Module and export names are already-loaded atoms; this never synthesizes keys.
    :code.all_loaded()
    |> Enum.flat_map(fn {module, _path} ->
      exported_names =
        try do
          module.module_info(:exports) |> Enum.map(&elem(&1, 0))
        rescue
          _exception -> []
        end

      [module | exported_names]
    end)
    |> Enum.uniq()
    |> Enum.filter(&(Atom.to_string(&1) |> String.valid?()))
    |> Enum.sort_by(&Atom.to_string/1)
  end

  defp spawn_bounded_call(manifest, adapter, adapter_options, lifecycle_options) do
    observer = self()
    call_tag = make_ref()

    {caller, caller_ref} =
      spawn_monitor(fn ->
        result =
          CadenceImport.bounded_dry_run(
            manifest,
            adapter,
            adapter_options,
            lifecycle_options
          )

        send(observer, {:bounded_caller_result, call_tag, self(), result})

        receive do
          {:finish_bounded_caller, ^call_tag} -> :ok
        end
      end)

    {caller, caller_ref, call_tag}
  end

  defp cancel_trapping_call(adapter, adapter_options, phase) do
    {caller, caller_ref, call_tag} =
      spawn_bounded_call(
        valid_manifest_with_authority(),
        adapter,
        adapter_options,
        timeout: 5_000
      )

    {worker, preceding_workers} =
      case phase do
        :capabilities ->
          assert_receive {:adapter_callback_started, :capabilities, worker}
          assert_receive {:adapter_callback_trapping, :capabilities, ^worker}
          {worker, []}

        :dry_run ->
          assert_receive {:adapter_callback_started, :capabilities, capabilities_worker}

          assert_receive {:adapter_callback_started, :dry_run, worker, _request,
                          %{"mode" => "trap_never"}}

          assert_receive {:adapter_callback_trapping, :dry_run, ^worker}
          {worker, [capabilities_worker]}
      end

    {controller, guardian} = lifecycle_owners(worker)
    Process.exit(caller, :kill)
    assert_receive {:DOWN, ^caller_ref, :process, ^caller, :killed}

    for process <- [caller, worker, controller, guardian | preceding_workers] do
      assert_process_dead(process)
    end

    refute_receive {:bounded_caller_result, ^call_tag, ^caller, _result}, 10
    [caller, worker, controller, guardian | preceding_workers]
  end

  defp lifecycle_owners(worker) do
    {:monitored_by, owners} = Process.info(worker, :monitored_by)

    owners_by_role =
      Map.new(owners, fn owner ->
        {lifecycle_role(owner), owner}
      end)

    assert Map.keys(owners_by_role) |> Enum.sort() == [:controller, :guardian]
    {Map.fetch!(owners_by_role, :controller), Map.fetch!(owners_by_role, :guardian)}
  end

  defp lifecycle_role(process) do
    case Process.info(process, :dictionary) do
      {:dictionary, dictionary} ->
        case List.keyfind(
               dictionary,
               {OrbitalDynamics.CadenceImport.ConsumerConformance, :bounded_lifecycle_role},
               0
             ) do
          {_key, role} -> role
          nil -> :unowned
        end

      nil ->
        :unowned
    end
  end

  defp lifecycle_role_pids do
    Process.list()
    |> Enum.filter(&(lifecycle_role(&1) in [:controller, :guardian]))
    |> MapSet.new()
  end

  defp assert_role_processes_restored(expected, attempts \\ 100)

  defp assert_role_processes_restored(expected, attempts) when attempts > 0 do
    if lifecycle_role_pids() == expected do
      assert lifecycle_role_pids() == expected
    else
      Process.sleep(1)
      assert_role_processes_restored(expected, attempts - 1)
    end
  end

  defp assert_role_processes_restored(expected, 0) do
    assert lifecycle_role_pids() == expected
  end

  defp observer_monitors do
    {:monitors, monitors} = Process.info(self(), :monitors)
    MapSet.new(monitors)
  end

  defp observer_messages do
    {:messages, messages} = Process.info(self(), :messages)
    messages
  end

  defp assert_no_lifecycle_messages(processes) do
    conformance = OrbitalDynamics.CadenceImport.ConsumerConformance

    refute_receive {{^conformance, :bounded_callback, _ref}, _kind, _one}, 20
    refute_receive {{^conformance, :bounded_callback, _ref}, _kind, _one, _two}, 20

    for process <- Enum.uniq(processes) do
      refute_receive {:DOWN, _ref, :process, ^process, _reason}, 0
    end
  end

  defp assert_process_dead(pid, attempts \\ 100)

  defp assert_process_dead(pid, attempts) when attempts > 0 do
    if Process.alive?(pid) do
      Process.sleep(1)
      assert_process_dead(pid, attempts - 1)
    else
      refute Process.alive?(pid)
    end
  end

  defp assert_process_dead(pid, 0), do: refute(Process.alive?(pid))

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
