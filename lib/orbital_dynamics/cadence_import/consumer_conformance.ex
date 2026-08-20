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

  defp preflight_input(input) do
    case OuterAdmission.validate(input) do
      :ok ->
        :ok

      {:error, %{"code" => code, "message" => message, "details" => details}} ->
        typed_error(code, message, details)
    end
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
