defmodule OrbitalDynamics.CadenceImport.ConsumerConformance do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{OuterAdmission, SourceIdentifierPolicy}
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.JsonSafety

  @adapter_capabilities %{
    "contract" => "cadence_consumer_dry_run_adapter.v1",
    "operations" => ["dry_run"],
    "writes" => false
  }
  @campaign_contract "campaign_strategy.v3"
  @manifest_contract "cadence_import_manifest.v1"
  @request_type "cadence_consumer_dry_run_request.v1"
  @result_type "cadence_consumer_conformance.v1"
  @error_type "cadence_consumer_conformance_error.v1"
  @identity_algorithm "erlang_term_to_binary_deterministic_sha256.v1"
  @max_adapter_options 2_048
  @max_receive_interval_ms 60_000
  @authority_fields ~w(eligibility_status authority_context authority_context_evaluation)
  @acknowledgement_fields ~w(
    status
    source_identity
    authority_evidence
    manifest_semantic_sha256
    idempotency_identity
  )

  @spec run(term(), term(), term()) :: {:ok, map()} | {:error, map()}
  def run(artifact_or_manifest, adapter, opts) do
    with :ok <- preflight_input(artifact_or_manifest),
         {:ok, adapter_options} <- normalize_options(opts),
         {:ok, manifest} <- validate_input(artifact_or_manifest),
         {:ok, adapter_name, capabilities} <- validate_adapter(adapter),
         request <- build_request(manifest, adapter_name, capabilities, adapter_options),
         {:ok, acknowledgement} <- call_adapter(adapter, request, adapter_options),
         :ok <- validate_acknowledgement(acknowledgement, request) do
      {:ok, conformance_result(request)}
    end
  rescue
    exception ->
      typed_error(
        "conformance_exception",
        "Cadence consumer conformance did not complete",
        %{"exception" => exception_name(exception)}
      )
  catch
    kind, _reason ->
      typed_error(
        "conformance_#{kind}",
        "Cadence consumer conformance did not complete",
        %{}
      )
  end

  @spec run(term(), term(), term(), term()) :: {:ok, map()} | {:error, map()}
  def run(artifact_or_manifest, adapter, adapter_opts, lifecycle_opts) do
    with {:ok, timeout} <- normalize_lifecycle_options(lifecycle_opts),
         :ok <- preflight_input(artifact_or_manifest),
         {:ok, adapter_options} <- normalize_options(adapter_opts),
         {:ok, manifest} <- validate_input(artifact_or_manifest),
         deadline <- monotonic_deadline(timeout),
         {:ok, adapter_name, capabilities} <-
           validate_bounded_adapter(adapter, deadline, timeout),
         request <- build_request(manifest, adapter_name, capabilities, adapter_options),
         {:ok, acknowledgement} <-
           call_bounded_adapter(
             adapter,
             request,
             adapter_options,
             deadline,
             timeout
           ),
         :ok <- validate_acknowledgement(acknowledgement, request) do
      {:ok, conformance_result(request)}
    end
  rescue
    exception ->
      typed_error(
        "conformance_exception",
        "Cadence consumer conformance did not complete",
        %{"exception" => exception_name(exception)}
      )
  catch
    kind, _reason ->
      typed_error(
        "conformance_#{kind}",
        "Cadence consumer conformance did not complete",
        %{}
      )
  end

  defp preflight_input(input) do
    case OuterAdmission.validate(input) do
      :ok ->
        :ok

      {:error, %{"code" => code, "message" => message, "details" => details}} ->
        typed_error(code, message, details)
    end
  end

  defp normalize_lifecycle_options(lifecycle_opts) do
    collect_lifecycle_options(lifecycle_opts, :missing, 0)
  end

  defp collect_lifecycle_options([], timeout, 1), do: {:ok, timeout}

  defp collect_lifecycle_options([], :missing, 0) do
    typed_error(
      "invalid_timeout_options",
      "bounded dry-run requires exactly one timeout option",
      %{"required_option" => "timeout"}
    )
  end

  defp collect_lifecycle_options([{:timeout, _duplicate} | _tail], _previous, 1) do
    typed_error(
      "invalid_timeout_options",
      "bounded dry-run timeout option must not be duplicated",
      %{"duplicate_key" => "timeout", "examined_item_count" => 2}
    )
  end

  defp collect_lifecycle_options([{:timeout, timeout} | tail], :missing, 0)
       when is_integer(timeout) and timeout > 0 do
    collect_lifecycle_options(tail, timeout, 1)
  end

  defp collect_lifecycle_options([{:timeout, _timeout} | _tail], :missing, 0) do
    typed_error(
      "invalid_timeout_options",
      "bounded dry-run timeout must be a positive integer number of milliseconds",
      %{"option" => "timeout"}
    )
  end

  defp collect_lifecycle_options([{key, _value} | _tail], _timeout, count)
       when is_atom(key) do
    typed_error(
      "invalid_timeout_options",
      "bounded dry-run lifecycle options contain an unsupported key",
      %{"unsupported_key" => Atom.to_string(key), "invalid_item_position" => count + 1}
    )
  end

  defp collect_lifecycle_options([_entry | _tail], _timeout, count) do
    typed_error(
      "invalid_timeout_options",
      "bounded dry-run lifecycle options must contain atom-key tuple entries",
      %{"invalid_item_position" => count + 1}
    )
  end

  defp collect_lifecycle_options(_improper_tail, _timeout, count) do
    typed_error(
      "invalid_timeout_options",
      "bounded dry-run lifecycle options must be a proper list",
      %{"validated_item_count" => count}
    )
  end

  defp normalize_options(opts) do
    with {:ok, options} <- collect_options(opts, %{}, MapSet.new(), 0) do
      normalize_json(
        options,
        "Cadence consumer adapter options",
        "invalid_options",
        "adapter options must be bounded JSON-safe values"
      )
    end
  end

  defp collect_options([], options, _seen, _count), do: {:ok, options}

  defp collect_options([_entry | _tail], _options, _seen, @max_adapter_options) do
    typed_error("invalid_options", "adapter options exceed their item limit", %{
      "actual_item_count_at_least" => @max_adapter_options + 1,
      "max_item_count" => @max_adapter_options
    })
  end

  defp collect_options([{key, value} | tail], options, seen, count) when is_atom(key) do
    item_count = count + 1

    if MapSet.member?(seen, key) do
      typed_error("invalid_options", "adapter options contain a duplicate key", %{
        "duplicate_key" => Atom.to_string(key),
        "examined_item_count" => item_count
      })
    else
      collect_options(
        tail,
        Map.put(options, Atom.to_string(key), value),
        MapSet.put(seen, key),
        item_count
      )
    end
  end

  defp collect_options([_entry | _tail], _options, _seen, count) do
    typed_error("invalid_options", "adapter options must contain atom-key tuple entries", %{
      "invalid_item_position" => count + 1
    })
  end

  defp collect_options(_improper_tail, _options, _seen, count) do
    typed_error("invalid_options", "adapter options must be a proper list", %{
      "validated_item_count" => count
    })
  end

  defp validate_input(%_module{} = _input) do
    typed_error("invalid_outer_input", "Cadence dry-run input must be a plain JSON map", %{})
  end

  defp validate_input(%{} = input) do
    cond do
      campaign_artifact?(input) -> validate_campaign_artifact(input)
      input["schema_contract"] == @manifest_contract -> validate_direct_manifest(input)
      true -> unsupported_input(input)
    end
  end

  defp validate_input(_input) do
    typed_error("invalid_outer_input", "Cadence dry-run input must be a JSON map", %{})
  end

  defp campaign_artifact?(input) do
    input["schema_contract"] == @campaign_contract or
      (input["schema_version"] == 3 and
         input["planner"] == "OrbitalDynamics.CampaignPlanner.V3")
  end

  defp validate_campaign_artifact(artifact) do
    with {:ok, _report} <- validate_schema(artifact, @campaign_contract),
         {:ok, manifest} <- fetch_embedded_manifest(artifact),
         :ok <- validate_campaign_manifest_binding(artifact, manifest) do
      {:ok, manifest}
    end
  end

  defp validate_direct_manifest(manifest) do
    with {:ok, _report} <- validate_schema(manifest, @manifest_contract),
         :ok <- validate_manifest_binding(manifest) do
      {:ok, manifest}
    end
  end

  defp validate_schema(artifact, contract) do
    case Schema.validate_artifact(artifact, contract: contract) do
      {:ok, report} ->
        {:ok, report}

      {:error, report} ->
        schema_error(contract, report)

      _other ->
        typed_error(
          "invalid_validation_return",
          "schema validation returned an unsupported result",
          %{"validated_contract" => contract}
        )
    end
  end

  defp schema_error(contract, report) do
    code =
      cond do
        authority_issue?(report) -> "authority_evidence_tampered"
        identity_issue?(report) -> "source_identity_tampered"
        true -> "invalid_artifact"
      end

    typed_error(code, "input failed #{contract} validation", %{
      "validated_contract" => contract,
      "validation_report" => report
    })
  end

  defp authority_issue?(%{"errors" => errors}) when is_list(errors) do
    Enum.any?(errors, fn
      %{"path" => path} when is_binary(path) ->
        String.contains?(path, "authority_context") or
          String.contains?(path, "eligibility_status")

      _issue ->
        false
    end)
  end

  defp authority_issue?(_report), do: false

  defp identity_issue?(%{"errors" => errors}) when is_list(errors) do
    Enum.any?(errors, fn
      %{"path" => path} when is_binary(path) ->
        String.contains?(path, "cadence_import_manifest.source_artifact") or
          String.contains?(path, "cadence_import_manifest.manifest_id") or
          String.contains?(path, "cadence_import_manifest.provenance.source_artifact")

      _issue ->
        false
    end)
  end

  defp identity_issue?(_report), do: false

  defp fetch_embedded_manifest(%{"cadence_import_manifest" => %{} = manifest}),
    do: {:ok, manifest}

  defp fetch_embedded_manifest(_artifact) do
    typed_error(
      "missing_cadence_import_manifest",
      "a V3 campaign artifact must contain its validated Cadence import manifest",
      %{}
    )
  end

  defp validate_campaign_manifest_binding(
         %{
           "strategy_metadata" => %{"strategy_id" => source_id},
           "cadence_import_manifest" => %{} = manifest
         } = artifact,
         manifest
       )
       when is_binary(source_id) do
    with :ok <- validate_manifest_binding(manifest),
         :ok <- validate_campaign_source_identity(manifest, source_id) do
      validate_authority_copy(authority_evidence(artifact), manifest)
    end
  end

  defp validate_campaign_manifest_binding(_artifact, _manifest) do
    typed_error(
      "invalid_artifact_binding",
      "validated V3 campaign identity could not be bound to its embedded manifest",
      %{}
    )
  end

  defp validate_campaign_source_identity(manifest, source_id) do
    if manifest["source_artifact_id"] == source_id do
      :ok
    else
      identity_error("manifest source identity does not match the enclosing V3 campaign")
    end
  end

  defp validate_authority_copy(expected, manifest) do
    if authority_evidence(manifest) == expected do
      :ok
    else
      typed_error(
        "authority_evidence_tampered",
        "manifest authority evidence does not match the enclosing V3 campaign",
        %{}
      )
    end
  end

  defp validate_manifest_binding(manifest) do
    source_type = manifest["source_artifact_type"]
    source_id = manifest["source_artifact_id"]
    provenance = manifest["provenance"]

    cond do
      source_type != @campaign_contract ->
        typed_error(
          "unsupported_source",
          "Cadence consumer dry-run supports only V3 campaign manifests",
          %{"source_artifact_type" => json_scalar(source_type)}
        )

      not (is_binary(source_id) and source_id != "") ->
        identity_error("manifest source artifact identity is missing or malformed")

      manifest["manifest_id"] != SourceIdentifierPolicy.manifest(source_id) ->
        identity_error("manifest identity does not match its source artifact identity")

      not is_map(provenance) ->
        identity_error("manifest provenance is missing or malformed")

      provenance["source_artifact_type"] != source_type or
          provenance["source_artifact_id"] != source_id ->
        identity_error("manifest provenance does not preserve its source identity")

      true ->
        :ok
    end
  end

  defp identity_error(message), do: typed_error("source_identity_tampered", message, %{})

  defp unsupported_input(input) do
    typed_error(
      "unsupported_input",
      "Cadence dry-run accepts only a V3 campaign artifact or its import manifest",
      %{"declared_contract" => json_scalar(input["schema_contract"])}
    )
  end

  defp validate_adapter(adapter) when is_atom(adapter) do
    with {:module, ^adapter} <- Code.ensure_loaded(adapter),
         true <- function_exported?(adapter, :capabilities, 0),
         true <- function_exported?(adapter, :dry_run, 2),
         {:ok, declared} <- call_capabilities(adapter),
         {:ok, capabilities} <-
           normalize_json(
             declared,
             "Cadence consumer adapter capabilities",
             "invalid_adapter_capabilities",
             "adapter capabilities must be bounded JSON-safe values"
           ),
         :ok <- validate_adapter_capabilities(capabilities) do
      {:ok, Atom.to_string(adapter), capabilities}
    else
      {:error, _error} = failure ->
        failure

      _missing ->
        typed_error(
          "invalid_adapter",
          "adapter must be a loaded module exporting capabilities/0 and dry_run/2",
          %{}
        )
    end
  end

  defp validate_adapter(_adapter) do
    typed_error("invalid_adapter", "adapter must be an existing module atom", %{})
  end

  defp validate_bounded_adapter(adapter, deadline, timeout) when is_atom(adapter) do
    with {:module, ^adapter} <- Code.ensure_loaded(adapter),
         true <- function_exported?(adapter, :capabilities, 0),
         true <- function_exported?(adapter, :dry_run, 2),
         {:ok, declared} <- call_bounded_capabilities(adapter, deadline, timeout),
         {:ok, capabilities} <-
           normalize_json(
             declared,
             "Cadence consumer adapter capabilities",
             "invalid_adapter_capabilities",
             "adapter capabilities must be bounded JSON-safe values"
           ),
         :ok <- validate_adapter_capabilities(capabilities) do
      {:ok, Atom.to_string(adapter), capabilities}
    else
      {:error, _error} = failure ->
        failure

      _missing ->
        typed_error(
          "invalid_adapter",
          "adapter must be a loaded module exporting capabilities/0 and dry_run/2",
          %{}
        )
    end
  end

  defp validate_bounded_adapter(_adapter, _deadline, _timeout) do
    typed_error("invalid_adapter", "adapter must be an existing module atom", %{})
  end

  defp call_capabilities(adapter) do
    try do
      {:ok, apply(adapter, :capabilities, [])}
    rescue
      exception ->
        typed_error(
          "adapter_capabilities_exception",
          "adapter capabilities raised an exception",
          %{"exception" => exception_name(exception)}
        )
    catch
      kind, _reason ->
        typed_error(
          "adapter_capabilities_#{kind}",
          "adapter capabilities did not return",
          %{}
        )
    end
  end

  defp call_bounded_capabilities(adapter, deadline, timeout) do
    case bounded_callback(deadline, fn -> apply(adapter, :capabilities, []) end) do
      {:returned, declared} ->
        {:ok, declared}

      :timeout ->
        callback_timeout_error(:capabilities, timeout)

      {:exception, exception} ->
        typed_error(
          "adapter_capabilities_exception",
          "adapter capabilities callback raised an exception",
          %{"exception" => exception, "phase" => "capabilities"}
        )

      :throw ->
        callback_nonreturn_error(:capabilities, :throw)

      :exit ->
        callback_nonreturn_error(:capabilities, :exit)

      {:worker_death, reason} ->
        callback_worker_death_error(:capabilities, reason)

      {:controller_death, reason} ->
        callback_controller_death_error(:capabilities, reason)
    end
  end

  defp validate_adapter_capabilities(@adapter_capabilities), do: :ok

  defp validate_adapter_capabilities(capabilities) do
    typed_error(
      "unsupported_adapter_capabilities",
      "adapter must declare the exact dry-run-only no-write capability surface",
      %{"declared" => capabilities, "required" => @adapter_capabilities}
    )
  end

  defp build_request(manifest, adapter_name, capabilities, adapter_options) do
    source_identity = source_identity(manifest)
    authority_evidence = authority_evidence(manifest)
    manifest_sha256 = semantic_sha256(manifest)

    identity_basis = %{
      "adapter" => adapter_name,
      "adapter_capabilities" => capabilities,
      "adapter_options" => adapter_options,
      "authority_evidence" => authority_evidence,
      "manifest_semantic_sha256" => manifest_sha256,
      "source_identity" => source_identity
    }

    idempotency_identity =
      "cadence_consumer_dry_run:sha256:" <> semantic_sha256(identity_basis)

    Map.merge(identity_basis, %{
      "type" => @request_type,
      "operation" => "dry_run",
      "manifest" => manifest,
      "idempotency_identity" => idempotency_identity
    })
  end

  defp source_identity(manifest) do
    Map.take(manifest, ~w(source_artifact_type source_artifact_id manifest_id))
  end

  defp authority_evidence(manifest), do: Map.take(manifest, @authority_fields)

  defp call_adapter(adapter, request, adapter_options) do
    result =
      try do
        {:returned, apply(adapter, :dry_run, [request, adapter_options])}
      rescue
        exception -> {:exception, exception_name(exception)}
      catch
        kind, _reason -> {:caught, Atom.to_string(kind)}
      end

    case result do
      {:returned, {:ok, acknowledgement}} ->
        normalize_json(
          acknowledgement,
          "Cadence consumer adapter acknowledgement",
          "invalid_adapter_return",
          "adapter acknowledgement must be a bounded JSON-safe map"
        )

      {:returned, {:error, reason}} ->
        typed_error("adapter_error", "adapter rejected the dry-run request", %{
          "adapter_error" => adapter_error_evidence(reason)
        })

      {:returned, _other} ->
        typed_error(
          "invalid_adapter_return",
          "adapter must return {:ok, acknowledgement} or {:error, reason}",
          %{}
        )

      {:exception, exception} ->
        typed_error("adapter_exception", "adapter dry_run raised an exception", %{
          "exception" => exception
        })

      {:caught, kind} ->
        typed_error("adapter_#{kind}", "adapter dry_run did not return", %{})
    end
  end

  defp call_bounded_adapter(adapter, request, adapter_options, deadline, timeout) do
    result =
      bounded_callback(deadline, fn ->
        apply(adapter, :dry_run, [request, adapter_options])
      end)

    case result do
      {:returned, {:ok, acknowledgement}} ->
        normalize_json(
          acknowledgement,
          "Cadence consumer adapter acknowledgement",
          "invalid_adapter_return",
          "adapter acknowledgement must be a bounded JSON-safe map"
        )

      {:returned, {:error, reason}} ->
        typed_error("adapter_error", "adapter rejected the dry-run request", %{
          "adapter_error" => adapter_error_evidence(reason)
        })

      {:returned, _other} ->
        typed_error(
          "invalid_adapter_return",
          "adapter must return {:ok, acknowledgement} or {:error, reason}",
          %{}
        )

      :timeout ->
        callback_timeout_error(:dry_run, timeout)

      {:exception, exception} ->
        typed_error(
          "adapter_dry_run_exception",
          "adapter dry_run callback raised an exception",
          %{"exception" => exception, "phase" => "dry_run"}
        )

      :throw ->
        callback_nonreturn_error(:dry_run, :throw)

      :exit ->
        callback_nonreturn_error(:dry_run, :exit)

      {:worker_death, reason} ->
        callback_worker_death_error(:dry_run, reason)

      {:controller_death, reason} ->
        callback_controller_death_error(:dry_run, reason)
    end
  end

  defp monotonic_deadline(timeout) do
    System.monotonic_time() + System.convert_time_unit(timeout, :millisecond, :native)
  end

  defp bounded_callback(deadline, callback) do
    if deadline_expired?(deadline) do
      :timeout
    else
      caller = self()
      message_ref = make_ref()
      message_tag = {__MODULE__, :bounded_callback, message_ref}

      {guardian, guardian_ref} =
        spawn_monitor(fn ->
          lifecycle_guardian(caller, message_tag, deadline, callback)
        end)

      await_lifecycle_ready(guardian, guardian_ref, message_tag)
    end
  end

  defp await_lifecycle_ready(guardian, guardian_ref, message_tag) do
    receive do
      {^message_tag, :lifecycle_ready, ^guardian, controller} ->
        controller_ref = Process.monitor(controller)
        send(guardian, {message_tag, :request_ready, self()})

        await_lifecycle_outcome(%{
          controller: controller,
          controller_down: nil,
          controller_ref: controller_ref,
          guardian: guardian,
          guardian_down: nil,
          guardian_ref: guardian_ref,
          message_tag: message_tag
        })

      {:DOWN, ^guardian_ref, :process, ^guardian, reason} ->
        Process.demonitor(guardian_ref, [:flush])
        drain_request_lifecycle_messages(message_tag)
        {:controller_death, reason}
    end
  end

  defp await_lifecycle_outcome(state) do
    receive do
      {message_tag, :controller_result, controller, outcome}
      when message_tag == state.message_tag and controller == state.controller ->
        await_lifecycle_shutdown(state, outcome)

      {message_tag, :controller_cleanup, controller, outcome}
      when message_tag == state.message_tag and controller == state.controller ->
        await_lifecycle_shutdown(state, outcome)

      {:DOWN, controller_ref, :process, controller, reason}
      when controller_ref == state.controller_ref and controller == state.controller ->
        state
        |> Map.put(:controller_down, reason)
        |> lifecycle_down_or_continue()

      {:DOWN, guardian_ref, :process, guardian, reason}
      when guardian_ref == state.guardian_ref and guardian == state.guardian ->
        state
        |> Map.put(:guardian_down, reason)
        |> lifecycle_down_or_continue()
    end
  end

  defp lifecycle_down_or_continue(%{controller_down: nil} = state),
    do: await_lifecycle_outcome(state)

  defp lifecycle_down_or_continue(%{guardian_down: nil} = state),
    do: await_lifecycle_outcome(state)

  defp lifecycle_down_or_continue(state) do
    reason = state.controller_down || state.guardian_down
    finish_request_lifecycle(state)
    {:controller_death, reason}
  end

  defp await_lifecycle_shutdown(state, outcome) do
    cond do
      state.controller_down == nil ->
        receive do
          {:DOWN, controller_ref, :process, controller, reason}
          when controller_ref == state.controller_ref and controller == state.controller ->
            await_lifecycle_shutdown(Map.put(state, :controller_down, reason), outcome)

          {:DOWN, guardian_ref, :process, guardian, reason}
          when guardian_ref == state.guardian_ref and guardian == state.guardian ->
            await_lifecycle_shutdown(Map.put(state, :guardian_down, reason), outcome)
        end

      state.guardian_down == nil ->
        receive do
          {:DOWN, guardian_ref, :process, guardian, reason}
          when guardian_ref == state.guardian_ref and guardian == state.guardian ->
            await_lifecycle_shutdown(Map.put(state, :guardian_down, reason), outcome)
        end

      true ->
        finish_request_lifecycle(state)
        outcome
    end
  end

  defp finish_request_lifecycle(state) do
    Process.demonitor(state.controller_ref, [:flush])
    Process.demonitor(state.guardian_ref, [:flush])
    drain_request_lifecycle_messages(state.message_tag)
    :ok
  end

  defp lifecycle_guardian(caller, message_tag, deadline, callback) do
    Process.put({__MODULE__, :bounded_lifecycle_role}, :guardian)
    caller_ref = Process.monitor(caller)
    guardian = self()

    {controller, controller_ref} =
      spawn_monitor(fn ->
        lifecycle_controller(caller, guardian, message_tag, deadline)
      end)

    send(caller, {message_tag, :lifecycle_ready, guardian, controller})

    guardian_loop(%{
      armed: false,
      callback: callback,
      caller: caller,
      caller_down: false,
      caller_ref: caller_ref,
      controller: controller,
      controller_down: false,
      controller_ready: false,
      controller_ref: controller_ref,
      deadline: deadline,
      deadline_notified: false,
      finalized: false,
      message_tag: message_tag,
      request_ready: false,
      worker: nil,
      worker_ref: nil
    })
  end

  defp guardian_loop(state) do
    state = state |> guardian_maybe_arm_controller() |> guardian_maybe_start_worker()

    receive do
      {message_tag, :request_ready, caller}
      when message_tag == state.message_tag and caller == state.caller ->
        guardian_loop(%{state | request_ready: true})

      {message_tag, :controller_ready, controller}
      when message_tag == state.message_tag and controller == state.controller ->
        guardian_loop(%{state | controller_ready: true})

      {message_tag, :worker_booted, worker}
      when message_tag == state.message_tag and worker == state.worker ->
        send(state.controller, {state.message_tag, :worker_ready, worker})
        guardian_loop(%{state | callback: nil})

      {message_tag, :controller_finalize, controller}
      when message_tag == state.message_tag and controller == state.controller ->
        state = guardian_cleanup_worker(state)
        send(controller, {state.message_tag, :guardian_cleaned, self()})
        guardian_loop(%{state | finalized: true})

      {:DOWN, caller_ref, :process, caller, _reason}
      when caller_ref == state.caller_ref and caller == state.caller ->
        state = guardian_cleanup_worker(%{state | caller_down: true})
        send(state.controller, {state.message_tag, :caller_down, self()})
        guardian_loop(state)

      {:DOWN, controller_ref, :process, controller, reason}
      when controller_ref == state.controller_ref and controller == state.controller ->
        guardian_controller_down(state, reason)

      {:DOWN, worker_ref, :process, worker, _reason}
      when worker_ref == state.worker_ref and worker == state.worker ->
        Process.demonitor(worker_ref, [:flush])
        guardian_loop(%{state | worker: nil, worker_ref: nil})
    after
      receive_interval(state.deadline) ->
        guardian_loop(guardian_check_deadline(state))
    end
  end

  defp guardian_maybe_arm_controller(state) do
    if state.controller_ready and state.request_ready and not state.armed do
      send(state.controller, {state.message_tag, :controller_armed, self()})
      %{state | armed: true}
    else
      state
    end
  end

  defp guardian_maybe_start_worker(state) do
    cond do
      state.finalized or state.caller_down or state.worker != nil or
          not state.armed ->
        guardian_check_deadline(state)

      deadline_expired?(state.deadline) ->
        guardian_check_deadline(state)

      true ->
        guardian = self()

        {worker, worker_ref} =
          spawn_monitor(fn ->
            lifecycle_worker(
              guardian,
              state.controller,
              state.message_tag,
              state.callback
            )
          end)

        %{state | worker: worker, worker_ref: worker_ref}
    end
  end

  defp guardian_check_deadline(%{armed: false} = state), do: state
  defp guardian_check_deadline(%{deadline_notified: true} = state), do: state

  defp guardian_check_deadline(state) do
    if deadline_expired?(state.deadline) do
      send(state.controller, {state.message_tag, :guardian_deadline, self()})

      state
      |> Map.put(:deadline_notified, true)
      |> guardian_cleanup_worker()
    else
      state
    end
  end

  defp guardian_controller_down(state, reason) do
    state = guardian_cleanup_worker(%{state | controller_down: true})

    if not state.finalized and not state.caller_down and Process.alive?(state.caller) do
      send(
        state.caller,
        {state.message_tag, :controller_cleanup, state.controller, {:controller_death, reason}}
      )
    end

    guardian_cleanup_and_exit(state)
  end

  defp guardian_cleanup_worker(%{worker: nil} = state), do: state

  defp guardian_cleanup_worker(state) do
    Process.exit(state.worker, :kill)

    receive do
      {:DOWN, worker_ref, :process, worker, _reason}
      when worker_ref == state.worker_ref and worker == state.worker ->
        :ok
    end

    Process.demonitor(state.worker_ref, [:flush])
    %{state | callback: nil, worker: nil, worker_ref: nil}
  end

  defp guardian_cleanup_and_exit(state) do
    Process.demonitor(state.caller_ref, [:flush])
    Process.demonitor(state.controller_ref, [:flush])
    drain_guardian_messages(state.message_tag)
    :ok
  end

  defp lifecycle_controller(caller, guardian, message_tag, deadline) do
    Process.put({__MODULE__, :bounded_lifecycle_role}, :controller)
    caller_ref = Process.monitor(caller)
    guardian_ref = Process.monitor(guardian)
    send(guardian, {message_tag, :controller_ready, self()})

    controller_loop(%{
      armed: false,
      caller: caller,
      caller_down: false,
      caller_ref: caller_ref,
      deadline: deadline,
      guardian: guardian,
      guardian_down: false,
      guardian_ref: guardian_ref,
      message_tag: message_tag,
      pending_outcome: nil,
      worker: nil,
      worker_ref: nil
    })
  end

  defp controller_loop(state) do
    if state.armed and deadline_expired?(state.deadline) do
      controller_finish(state, :timeout, not state.caller_down)
    else
      receive do
        {message_tag, :controller_armed, guardian}
        when message_tag == state.message_tag and guardian == state.guardian ->
          controller_loop(%{state | armed: true})

        {message_tag, :worker_ready, worker} when message_tag == state.message_tag ->
          worker_ref = Process.monitor(worker)
          state = %{state | worker: worker, worker_ref: worker_ref}

          cond do
            state.caller_down or not Process.alive?(state.caller) ->
              controller_finish(%{state | caller_down: true}, :timeout, false)

            deadline_expired?(state.deadline) ->
              controller_finish(state, :timeout, true)

            state.guardian_down ->
              controller_finish(state, {:controller_death, :guardian_down}, true)

            state.pending_outcome != nil ->
              controller_finish(state, state.pending_outcome, true)

            true ->
              send(worker, {state.message_tag, :execute, self()})
              controller_loop(state)
          end

        {message_tag, :worker_result, worker, outcome}
        when message_tag == state.message_tag and
               (state.worker == nil or worker == state.worker) ->
          if state.worker == nil do
            controller_loop(%{state | pending_outcome: outcome})
          else
            outcome = if deadline_expired?(state.deadline), do: :timeout, else: outcome
            controller_finish(state, outcome, not state.caller_down)
          end

        {message_tag, :guardian_deadline, guardian}
        when message_tag == state.message_tag and guardian == state.guardian ->
          controller_finish(state, :timeout, not state.caller_down)

        {message_tag, :caller_down, guardian}
        when message_tag == state.message_tag and guardian == state.guardian ->
          controller_finish(%{state | caller_down: true}, :timeout, false)

        {:DOWN, caller_ref, :process, caller, _reason}
        when caller_ref == state.caller_ref and caller == state.caller ->
          controller_finish(%{state | caller_down: true}, :timeout, false)

        {:DOWN, guardian_ref, :process, guardian, reason}
        when guardian_ref == state.guardian_ref and guardian == state.guardian ->
          controller_finish(
            %{state | guardian_down: true},
            {:controller_death, reason},
            not state.caller_down
          )

        {:DOWN, worker_ref, :process, worker, reason}
        when worker_ref == state.worker_ref and worker == state.worker ->
          controller_worker_down(state, reason)
      after
        controller_receive_interval(state) ->
          controller_loop(state)
      end
    end
  end

  defp controller_receive_interval(%{armed: false}), do: @max_receive_interval_ms
  defp controller_receive_interval(state), do: receive_interval(state.deadline)

  defp controller_worker_down(state, reason) do
    outcome =
      cond do
        state.caller_down or not Process.alive?(state.caller) ->
          :caller_down

        deadline_expired?(state.deadline) ->
          :timeout

        true ->
          receive do
            {message_tag, :worker_result, worker, worker_outcome}
            when message_tag == state.message_tag and worker == state.worker ->
              worker_outcome
          after
            0 -> {:worker_death, reason}
          end
      end

    Process.demonitor(state.worker_ref, [:flush])
    state = %{state | worker: nil, worker_ref: nil}

    case outcome do
      :caller_down -> controller_finish(%{state | caller_down: true}, :timeout, false)
      other -> controller_finish(state, other, true)
    end
  end

  defp controller_finish(state, outcome, deliver?) do
    state = controller_cleanup_worker(state)

    {state, deliver?} =
      if state.guardian_down do
        {state, deliver?}
      else
        send(state.guardian, {state.message_tag, :controller_finalize, self()})
        await_guardian_cleanup(state, deliver?)
      end

    Process.demonitor(state.caller_ref, [:flush])
    Process.demonitor(state.guardian_ref, [:flush])
    drain_controller_messages(state.message_tag)

    if deliver? and not state.caller_down and Process.alive?(state.caller) do
      send(state.caller, {state.message_tag, :controller_result, self(), outcome})
    end

    :ok
  end

  defp controller_cleanup_worker(%{worker: nil} = state), do: state

  defp controller_cleanup_worker(state) do
    Process.exit(state.worker, :kill)

    receive do
      {:DOWN, worker_ref, :process, worker, _reason}
      when worker_ref == state.worker_ref and worker == state.worker ->
        :ok
    end

    Process.demonitor(state.worker_ref, [:flush])
    drain_worker_results(state.message_tag, state.worker)
    %{state | worker: nil, worker_ref: nil}
  end

  defp await_guardian_cleanup(state, deliver?) do
    receive do
      {message_tag, :guardian_cleaned, guardian}
      when message_tag == state.message_tag and guardian == state.guardian ->
        {state, deliver?}

      {:DOWN, caller_ref, :process, caller, _reason}
      when caller_ref == state.caller_ref and caller == state.caller ->
        await_guardian_cleanup(%{state | caller_down: true}, false)

      {:DOWN, guardian_ref, :process, guardian, _reason}
      when guardian_ref == state.guardian_ref and guardian == state.guardian ->
        {%{state | guardian_down: true}, deliver?}
    end
  end

  defp lifecycle_worker(guardian, controller, message_tag, callback) do
    guardian_ref = Process.monitor(guardian)
    controller_ref = Process.monitor(controller)
    send(guardian, {message_tag, :worker_booted, self()})

    receive do
      {^message_tag, :execute, ^controller} ->
        outcome =
          try do
            {:returned, callback.()}
          rescue
            exception -> {:exception, exception_name(exception)}
          catch
            :throw, _reason -> :throw
            :exit, _reason -> :exit
          end

        send(controller, {message_tag, :worker_result, self(), outcome})

      {:DOWN, ^guardian_ref, :process, ^guardian, _reason} ->
        :ok

      {:DOWN, ^controller_ref, :process, ^controller, _reason} ->
        :ok
    end
  end

  defp drain_worker_results(message_tag, worker) do
    receive do
      {^message_tag, :worker_result, ^worker, _outcome} ->
        drain_worker_results(message_tag, worker)
    after
      0 -> :ok
    end
  end

  defp drain_request_lifecycle_messages(message_tag) do
    receive do
      {^message_tag, _kind, _one} -> drain_request_lifecycle_messages(message_tag)
      {^message_tag, _kind, _one, _two} -> drain_request_lifecycle_messages(message_tag)
    after
      0 -> :ok
    end
  end

  defp drain_guardian_messages(message_tag) do
    receive do
      {^message_tag, _kind, _one} -> drain_guardian_messages(message_tag)
      {^message_tag, _kind, _one, _two} -> drain_guardian_messages(message_tag)
    after
      0 -> :ok
    end
  end

  defp drain_controller_messages(message_tag) do
    receive do
      {^message_tag, _kind, _one} -> drain_controller_messages(message_tag)
      {^message_tag, _kind, _one, _two} -> drain_controller_messages(message_tag)
    after
      0 -> :ok
    end
  end

  defp deadline_expired?(deadline), do: System.monotonic_time() >= deadline

  defp receive_interval(deadline) do
    remaining = deadline - System.monotonic_time()

    remaining
    |> System.convert_time_unit(:native, :millisecond)
    |> max(1)
    |> min(@max_receive_interval_ms)
  end

  defp callback_timeout_error(phase, timeout) do
    phase_name = Atom.to_string(phase)

    typed_error(
      "adapter_#{phase_name}_timeout",
      "adapter #{phase_name} callback exceeded the bounded dry-run deadline",
      %{"phase" => phase_name, "timeout_ms" => timeout}
    )
  end

  defp callback_nonreturn_error(phase, kind) do
    phase_name = Atom.to_string(phase)
    kind_name = Atom.to_string(kind)

    typed_error(
      "adapter_#{phase_name}_#{kind_name}",
      "adapter #{phase_name} callback did not return",
      %{"phase" => phase_name, "termination" => kind_name}
    )
  end

  defp callback_worker_death_error(phase, reason) do
    phase_name = Atom.to_string(phase)

    typed_error(
      "adapter_#{phase_name}_worker_death",
      "adapter #{phase_name} monitored worker died before returning",
      %{"phase" => phase_name, "reason" => worker_death_reason(reason)}
    )
  end

  defp callback_controller_death_error(phase, reason) do
    phase_name = Atom.to_string(phase)

    typed_error(
      "adapter_#{phase_name}_controller_death",
      "adapter #{phase_name} lifecycle controller died before cleanup completed",
      %{"phase" => phase_name, "reason" => worker_death_reason(reason)}
    )
  end

  defp worker_death_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp worker_death_reason(reason), do: term_type(reason)

  defp validate_acknowledgement(%{} = acknowledgement, request) do
    missing = Enum.reject(@acknowledgement_fields, &Map.has_key?(acknowledgement, &1))

    cond do
      missing != [] ->
        typed_error(
          "invalid_adapter_return",
          "adapter acknowledgement is missing required fields",
          %{"missing_fields" => missing}
        )

      acknowledgement["status"] != "conformant" ->
        typed_error(
          "invalid_adapter_return",
          "adapter acknowledgement status must be conformant",
          %{}
        )

      acknowledgement["source_identity"] != request["source_identity"] ->
        typed_error(
          "adapter_identity_tampered",
          "adapter acknowledgement changed the source identity",
          %{}
        )

      acknowledgement["authority_evidence"] != request["authority_evidence"] ->
        typed_error(
          "adapter_authority_tampered",
          "adapter acknowledgement changed immutable authority evidence",
          %{}
        )

      acknowledgement["manifest_semantic_sha256"] !=
          request["manifest_semantic_sha256"] ->
        typed_error(
          "adapter_identity_tampered",
          "adapter acknowledgement changed the manifest semantic identity",
          %{}
        )

      acknowledgement["idempotency_identity"] != request["idempotency_identity"] ->
        typed_error(
          "adapter_idempotency_tampered",
          "adapter acknowledgement changed the idempotency identity",
          %{}
        )

      true ->
        :ok
    end
  end

  defp validate_acknowledgement(_acknowledgement, _request) do
    typed_error("invalid_adapter_return", "adapter acknowledgement must be a map", %{})
  end

  defp conformance_result(request) do
    core = %{
      "type" => @result_type,
      "status" => "conformant",
      "operation" => "dry_run",
      "adapter" => request["adapter"],
      "adapter_capabilities" => request["adapter_capabilities"],
      "source_identity" => request["source_identity"],
      "authority_evidence" => request["authority_evidence"],
      "manifest_evidence" => %{
        "schema_contract" => @manifest_contract,
        "semantic_sha256" => request["manifest_semantic_sha256"],
        "row_count" => get_in(request, ["manifest", "row_count"])
      },
      "conformance" => %{
        "adapter_acknowledgement_checked" => true,
        "adapter_capabilities_checked" => true,
        "authority_evidence_preserved" => true,
        "handoff_validated_before_delegation" => true,
        "identity_preserved" => true,
        "writes_permitted" => false
      }
    }

    Map.put(core, "idempotency", %{
      "identity" => request["idempotency_identity"],
      "algorithm" => @identity_algorithm,
      "semantic_output_sha256" => semantic_sha256(core)
    })
  end

  defp normalize_json(value, label, code, message) do
    try do
      {:ok, JsonSafety.normalize_input!(value, label)}
    rescue
      exception in ArgumentError ->
        typed_error(code, message, %{"reason" => Exception.message(exception)})
    end
  end

  defp adapter_error_evidence(reason) do
    case normalize_json(
           reason,
           "Cadence consumer adapter error",
           "invalid_adapter_error",
           "adapter error is not JSON-safe"
         ) do
      {:ok, normalized} -> normalized
      {:error, _error} -> %{"reason_type" => term_type(reason)}
    end
  end

  defp semantic_sha256(term) do
    term
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp typed_error(code, message, details) do
    {:error,
     %{
       "type" => @error_type,
       "status" => "error",
       "code" => code,
       "message" => message,
       "details" => details
     }}
  end

  defp exception_name(%{__struct__: module}) when is_atom(module), do: Atom.to_string(module)

  defp json_scalar(nil), do: :null
  defp json_scalar(:null), do: :null

  defp json_scalar(value) when is_binary(value) or is_boolean(value) or is_number(value),
    do: value

  defp json_scalar(value) when is_atom(value), do: Atom.to_string(value)
  defp json_scalar(_value), do: "unsupported"

  defp term_type(value) when is_atom(value), do: "atom"
  defp term_type(value) when is_binary(value), do: "string"
  defp term_type(value) when is_map(value), do: "map"
  defp term_type(value) when is_list(value), do: "list"
  defp term_type(value) when is_tuple(value), do: "tuple"
  defp term_type(_value), do: "unsupported"
end
