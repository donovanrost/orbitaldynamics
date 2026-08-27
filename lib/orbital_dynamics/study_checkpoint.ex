defmodule OrbitalDynamics.StudyCheckpoint do
  @moduledoc """
  Versioned local-study checkpoint storage.

  A checkpoint contains completed per-scenario propagation outcomes. Each entry
  retains its original manifest index and ID, carries its own content hash, and
  is covered by the checkpoint-level content hash. Writes sync a same-directory
  temporary file before atomic publication or replacement, so an interrupted
  process leaves a complete published checkpoint available for explicit resume.
  The portable implementation does not sync containing-directory metadata, so
  it does not claim durability across sudden power loss. The hashes provide
  local integrity evidence only; they are not signer-backed authenticity proof.

  This module is intentionally limited to local, between-scenario recovery. It
  is not a persistent queue, a distributed recovery protocol, an automatic
  retry policy, or a within-scenario integrator checkpoint.
  """

  alias OrbitalDynamics.{ScenarioRunner, Study}

  @schema_contract "study_checkpoint.v1"
  @schema_version 1
  @payload_encoding "erlang_term_v1"
  @hash_pattern ~r/^[0-9a-f]{64}$/

  @doc "Returns the checkpoint contract name."
  def schema_contract, do: @schema_contract

  @doc """
  Executes the missing scenarios for a new or existing local checkpoint.

  `execute_chunk` receives the chunk's scenarios and original manifest indexes.
  The optional `:test_hook` runs only after a completed chunk has been published.
  Returning `{:error, reason}` injects a deterministic interruption for tests
  without exposing a CLI fault switch. `:initial_publish_test_hook` is the
  corresponding test-only barrier after the initial temporary file has been
  synced and before its no-clobber publication.
  """
  def execute(
        %Study{} = study,
        checkpoint_config,
        identity_inputs,
        chunk_size,
        execute_chunk,
        opts \\ []
      )
      when is_map(checkpoint_config) and is_map(identity_inputs) and
             is_integer(chunk_size) and chunk_size > 0 and is_function(execute_chunk, 2) do
    with {:ok, path, mode} <- checkpoint_path_and_mode(checkpoint_config),
         {:ok, expected_identity} <- build_identity(study, identity_inputs),
         {:ok, checkpoint, reused_results} <-
           open_checkpoint(
             path,
             mode,
             expected_identity,
             Keyword.get(opts, :initial_publish_test_hook)
           ),
         {:ok, completed_checkpoint, run_results, run_indexes, run_chunk_count} <-
           execute_missing_chunks(
             checkpoint,
             expected_identity,
             study,
             path,
             chunk_size,
             execute_chunk,
             Keyword.get(opts, :test_hook)
           ),
         {:ok, checkpoint_sha256} <- file_sha256(path) do
      reused_indexes = Enum.map(reused_results, & &1.scenario_index)
      results = Enum.sort_by(reused_results ++ run_results, & &1.scenario_index)

      provenance = %{
        schema_contract: @schema_contract,
        schema_version: @schema_version,
        checkpoint_path: path,
        checkpoint_sha256: checkpoint_sha256,
        checkpoint_mode: Atom.to_string(mode),
        ordering: "source_manifest_scenario_order",
        scenario_count: length(study.scenarios),
        reused_scenario_count: length(reused_results),
        run_scenario_count: length(run_results),
        reused_scenario_indexes: reused_indexes,
        run_scenario_indexes: run_indexes,
        completed_scenario_count: length(results),
        completed_chunk_count: Map.fetch!(completed_checkpoint, "write_sequence"),
        run_completed_chunk_count: run_chunk_count,
        checkpoint_chunk_size: chunk_size,
        manifest_sha256: get_in(expected_identity, ["manifest", "sha256"]),
        study_sha256: get_in(expected_identity, ["study", "sha256"]),
        model_sha256: get_in(expected_identity, ["model", "sha256"]),
        run_options_sha256: get_in(expected_identity, ["run_options", "sha256"]),
        persistent_queue: false,
        automatic_retry: false,
        within_scenario_checkpoint: false,
        distributed_recovery: false,
        batch_recovery: false
      }

      {:ok, results, provenance}
    end
  end

  @doc """
  Validates a checkpoint and all of its entry hashes against current identities.

  The return value is summary evidence only; propagation payloads are not
  exposed through this validation API.
  """
  def validate_file(path, %Study{} = study, identity_inputs)
      when is_binary(path) and is_map(identity_inputs) do
    with {:ok, expected_identity} <- build_identity(study, identity_inputs),
         {:ok, checkpoint} <- read_checkpoint(path),
         {:ok, results} <- validate_checkpoint(checkpoint, expected_identity) do
      {:ok,
       %{
         schema_contract: @schema_contract,
         schema_version: @schema_version,
         scenario_count: length(study.scenarios),
         completed_scenario_count: length(results),
         completed_scenario_indexes: Enum.map(results, & &1.scenario_index),
         content_sha256: Map.fetch!(checkpoint, "content_sha256")
       }}
    end
  end

  defp checkpoint_path_and_mode(config) do
    path = Map.get(config, :path) || Map.get(config, "path")
    mode = Map.get(config, :mode) || Map.get(config, "mode")

    cond do
      not (is_binary(path) and path != "") ->
        {:error, {:invalid_checkpoint_option, :path}}

      mode not in [:create, :resume] ->
        {:error, {:invalid_checkpoint_option, :mode}}

      true ->
        {:ok, Path.expand(path), mode}
    end
  end

  defp build_identity(%Study{} = study, identity_inputs) do
    manifest = Map.get(identity_inputs, :manifest) || Map.get(identity_inputs, "manifest")
    model = Map.get(identity_inputs, :model) || Map.get(identity_inputs, "model")

    run_options =
      Map.get(identity_inputs, :run_options) || Map.get(identity_inputs, "run_options")

    with {:ok, manifest_identity} <- manifest_identity(manifest),
         :ok <- require_identity_input(:model, model),
         :ok <- require_identity_input(:run_options, run_options) do
      scenario_manifest =
        study.scenarios
        |> Enum.with_index()
        |> Enum.map(fn {scenario, scenario_index} ->
          %{
            "scenario_index" => scenario_index,
            "scenario_id" => identity(scenario.id),
            "scenario_sha256" => term_sha256(scenario)
          }
        end)

      {:ok,
       %{
         "manifest" => manifest_identity,
         "study" => %{
           "id" => identity(study.id),
           "scenario_count" => length(study.scenarios),
           "sha256" => term_sha256(study)
         },
         "model" => %{
           "propagator" => identity(study.propagator),
           "sha256" => term_sha256(model)
         },
         "run_options" => %{"sha256" => term_sha256(run_options)},
         "scenario_manifest" => scenario_manifest
       }}
    end
  rescue
    error in ArgumentError -> {:error, {:checkpoint_identity_error, Exception.message(error)}}
  end

  defp manifest_identity(%{} = manifest) do
    path = Map.get(manifest, :path) || Map.get(manifest, "path")
    sha256 = Map.get(manifest, :sha256) || Map.get(manifest, "sha256")

    cond do
      not (is_binary(path) and path != "") ->
        {:error, {:checkpoint_identity_required, :manifest_path}}

      not valid_sha256?(sha256) ->
        {:error, {:checkpoint_identity_required, :manifest_sha256}}

      true ->
        {:ok, %{"path" => Path.expand(path), "sha256" => sha256}}
    end
  end

  defp manifest_identity(_manifest),
    do: {:error, {:checkpoint_identity_required, :manifest}}

  defp require_identity_input(field, nil),
    do: {:error, {:checkpoint_identity_required, field}}

  defp require_identity_input(_field, _value), do: :ok

  defp open_checkpoint(path, :create, expected_identity, initial_publish_test_hook) do
    checkpoint =
      %{
        "schema_contract" => @schema_contract,
        "schema_version" => @schema_version,
        "identity" => expected_identity,
        "completed_scenario_count" => 0,
        "completed_scenarios" => [],
        "write_sequence" => 0
      }
      |> seal_checkpoint()

    with :ok <- atomic_write(path, checkpoint, :create, initial_publish_test_hook) do
      {:ok, checkpoint, []}
    end
  end

  defp open_checkpoint(path, :resume, expected_identity, _initial_publish_test_hook) do
    with {:ok, checkpoint} <- read_checkpoint(path),
         {:ok, results} <- validate_checkpoint(checkpoint, expected_identity) do
      {:ok, checkpoint, results}
    end
  end

  defp execute_missing_chunks(
         checkpoint,
         expected_identity,
         study,
         path,
         chunk_size,
         execute_chunk,
         test_hook
       ) do
    completed_indexes =
      checkpoint
      |> Map.fetch!("completed_scenarios")
      |> MapSet.new(&Map.fetch!(&1, "scenario_index"))

    missing_rows =
      expected_identity
      |> Map.fetch!("scenario_manifest")
      |> Enum.reject(&MapSet.member?(completed_indexes, Map.fetch!(&1, "scenario_index")))

    missing_rows
    |> Enum.chunk_every(chunk_size)
    |> Enum.reduce_while({:ok, checkpoint, [], [], 0}, fn chunk_rows,
                                                          {:ok, current, results, indexes,
                                                           chunk_count} ->
      chunk_indexes = Enum.map(chunk_rows, &Map.fetch!(&1, "scenario_index"))
      chunk_scenarios = Enum.map(chunk_indexes, &Enum.at(study.scenarios, &1))

      case execute_chunk.(chunk_scenarios, chunk_indexes) do
        chunk_results when is_list(chunk_results) ->
          with :ok <- validate_chunk_results(chunk_results, chunk_rows),
               {:ok, updated} <- append_chunk(current, chunk_results, path),
               :ok <-
                 invoke_test_hook(test_hook, %{
                   schema_contract: @schema_contract,
                   checkpoint_path: path,
                   checkpoint_sha256: file_sha256!(path),
                   chunk_number: chunk_count + 1,
                   completed_scenario_indexes: chunk_indexes,
                   published_completed_scenario_count:
                     Map.fetch!(updated, "completed_scenario_count")
                 }) do
            {:cont,
             {:ok, updated, results ++ chunk_results, indexes ++ chunk_indexes, chunk_count + 1}}
          else
            {:error, reason} -> {:halt, {:error, reason}}
          end

        other ->
          {:halt, {:error, {:invalid_checkpoint_chunk_result, other}}}
      end
    end)
  end

  defp validate_chunk_results(results, expected_rows) do
    expected =
      Map.new(expected_rows, fn row ->
        {Map.fetch!(row, "scenario_index"), Map.fetch!(row, "scenario_id")}
      end)

    cond do
      length(results) != map_size(expected) ->
        {:error, {:checkpoint_chunk_result_count_mismatch, map_size(expected), length(results)}}

      true ->
        results
        |> Enum.reduce_while(MapSet.new(), fn
          %ScenarioRunner.Result{} = result, seen ->
            expected_id = Map.get(expected, result.scenario_index)

            cond do
              is_nil(expected_id) ->
                {:halt, {:error, {:checkpoint_chunk_unexpected_index, result.scenario_index}}}

              MapSet.member?(seen, result.scenario_index) ->
                {:halt, {:error, {:checkpoint_chunk_duplicate_index, result.scenario_index}}}

              identity(result.scenario_id) != expected_id ->
                {:halt,
                 {:error,
                  {:checkpoint_chunk_scenario_id_mismatch, result.scenario_index, expected_id,
                   identity(result.scenario_id)}}}

              result.status not in [:ok, :error] ->
                {:halt,
                 {:error,
                  {:checkpoint_chunk_status_mismatch, result.scenario_index, result.status}}}

              true ->
                {:cont, MapSet.put(seen, result.scenario_index)}
            end

          other, _seen ->
            {:halt, {:error, {:invalid_checkpoint_chunk_result, other}}}
        end)
        |> case do
          %MapSet{} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp append_chunk(checkpoint, results, path) do
    entries =
      results
      |> Enum.map(&checkpoint_entry/1)
      |> then(&(Map.fetch!(checkpoint, "completed_scenarios") ++ &1))
      |> Enum.sort_by(&Map.fetch!(&1, "scenario_index"))

    updated =
      checkpoint
      |> Map.put("completed_scenarios", entries)
      |> Map.put("completed_scenario_count", length(entries))
      |> Map.update!("write_sequence", &(&1 + 1))
      |> seal_checkpoint()

    with :ok <- atomic_write(path, updated), do: {:ok, updated}
  end

  defp checkpoint_entry(%ScenarioRunner.Result{} = result) do
    payload = :erlang.term_to_binary(result, [:deterministic])

    %{
      "scenario_index" => result.scenario_index,
      "scenario_id" => identity(result.scenario_id),
      "payload_encoding" => @payload_encoding,
      "payload_sha256" => sha256(payload),
      "payload" => Base.encode64(payload)
    }
  end

  defp invoke_test_hook(nil, _event), do: :ok

  defp invoke_test_hook(test_hook, event) when is_function(test_hook, 1) do
    case test_hook.(event) do
      :ok -> :ok
      {:error, reason} -> {:error, {:checkpoint_test_interruption, reason}}
      other -> {:error, {:invalid_checkpoint_test_hook_result, other}}
    end
  end

  defp invoke_test_hook(_test_hook, _event),
    do: {:error, {:invalid_checkpoint_option, :test_hook}}

  defp read_checkpoint(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, checkpoint} <- decode_checkpoint(contents) do
      {:ok, checkpoint}
    else
      {:error, %{} = reason} -> {:error, reason}
      {:error, reason} -> {:error, %{reason: :checkpoint_read_error, path: path, error: reason}}
    end
  end

  defp decode_checkpoint(contents) do
    case :json.decode(contents) do
      %{} = checkpoint -> {:ok, checkpoint}
      _other -> {:error, %{reason: :invalid_checkpoint, error: :expected_json_object}}
    end
  rescue
    error ->
      {:error, %{reason: :invalid_checkpoint_json, error: Exception.message(error)}}
  end

  defp validate_checkpoint(checkpoint, expected_identity) do
    with :ok <- validate_checkpoint_header(checkpoint),
         :ok <- validate_checkpoint_content_hash(checkpoint),
         :ok <- validate_checkpoint_identity(checkpoint, expected_identity),
         {:ok, results} <- validate_checkpoint_entries(checkpoint, expected_identity) do
      {:ok, results}
    end
  end

  defp validate_checkpoint_header(checkpoint) do
    cond do
      Map.get(checkpoint, "schema_contract") != @schema_contract ->
        {:error, {:unsupported_checkpoint_contract, Map.get(checkpoint, "schema_contract")}}

      Map.get(checkpoint, "schema_version") != @schema_version ->
        {:error, {:unsupported_checkpoint_version, Map.get(checkpoint, "schema_version")}}

      not is_map(Map.get(checkpoint, "identity")) ->
        {:error, {:invalid_checkpoint, :missing_identity}}

      not is_list(Map.get(checkpoint, "completed_scenarios")) ->
        {:error, {:invalid_checkpoint, :missing_completed_scenarios}}

      not is_integer(Map.get(checkpoint, "completed_scenario_count")) or
          Map.get(checkpoint, "completed_scenario_count") < 0 ->
        {:error, {:invalid_checkpoint, :invalid_completed_scenario_count}}

      not is_integer(Map.get(checkpoint, "write_sequence")) or
          Map.get(checkpoint, "write_sequence") < 0 ->
        {:error, {:invalid_checkpoint, :invalid_write_sequence}}

      not valid_sha256?(Map.get(checkpoint, "content_sha256")) ->
        {:error, {:invalid_checkpoint, :invalid_content_sha256}}

      true ->
        :ok
    end
  end

  defp validate_checkpoint_content_hash(checkpoint) do
    expected = checkpoint |> Map.delete("content_sha256") |> term_sha256()
    actual = Map.fetch!(checkpoint, "content_sha256")

    if actual == expected do
      :ok
    else
      {:error, {:checkpoint_content_hash_mismatch, expected, actual}}
    end
  end

  defp validate_checkpoint_identity(checkpoint, expected_identity) do
    actual_identity = Map.fetch!(checkpoint, "identity")

    ["manifest", "model", "study", "run_options", "scenario_manifest"]
    |> Enum.find(&(Map.get(actual_identity, &1) != Map.get(expected_identity, &1)))
    |> case do
      nil ->
        :ok

      field ->
        {:error,
         {:checkpoint_identity_mismatch, field, Map.get(expected_identity, field),
          Map.get(actual_identity, field)}}
    end
  end

  defp validate_checkpoint_entries(checkpoint, expected_identity) do
    entries = Map.fetch!(checkpoint, "completed_scenarios")
    declared_count = Map.fetch!(checkpoint, "completed_scenario_count")
    invalid_entry_index = Enum.find_index(entries, &(not is_map(&1)))

    cond do
      declared_count != length(entries) ->
        {:error, {:checkpoint_completed_count_mismatch, declared_count, length(entries)}}

      not is_nil(invalid_entry_index) ->
        {:error, {:invalid_checkpoint_entry, invalid_entry_index}}

      Enum.map(entries, &Map.get(&1, "scenario_index")) !=
          Enum.sort(Enum.map(entries, &Map.get(&1, "scenario_index"))) ->
        {:error,
         {:checkpoint_rows_out_of_order, Enum.map(entries, &Map.get(&1, "scenario_index"))}}

      true ->
        scenario_rows =
          expected_identity
          |> Map.fetch!("scenario_manifest")
          |> Map.new(&{Map.fetch!(&1, "scenario_index"), &1})

        entries
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, [], MapSet.new()}, fn {entry, row_index},
                                                         {:ok, results, seen} ->
          case validate_checkpoint_entry(entry, row_index, scenario_rows, seen) do
            {:ok, result} ->
              {:cont, {:ok, results ++ [result], MapSet.put(seen, result.scenario_index)}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:ok, results, _seen} -> {:ok, results}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp validate_checkpoint_entry(entry, row_index, scenario_rows, seen) when is_map(entry) do
    required_fields = [
      "scenario_index",
      "scenario_id",
      "payload_encoding",
      "payload_sha256",
      "payload"
    ]

    missing_fields = Enum.reject(required_fields, &Map.has_key?(entry, &1))
    scenario_index = Map.get(entry, "scenario_index")
    expected_row = Map.get(scenario_rows, scenario_index)

    cond do
      missing_fields != [] ->
        {:error, {:checkpoint_entry_missing_fields, row_index, missing_fields}}

      not is_integer(scenario_index) ->
        {:error, {:checkpoint_entry_invalid_index, row_index, scenario_index}}

      MapSet.member?(seen, scenario_index) ->
        {:error, {:duplicate_checkpoint_scenario_index, scenario_index}}

      is_nil(expected_row) ->
        {:error, {:checkpoint_entry_unexpected_index, row_index, scenario_index}}

      Map.get(entry, "scenario_id") != Map.fetch!(expected_row, "scenario_id") ->
        {:error,
         {:checkpoint_entry_scenario_id_mismatch, scenario_index,
          Map.fetch!(expected_row, "scenario_id"), Map.get(entry, "scenario_id")}}

      Map.get(entry, "payload_encoding") != @payload_encoding ->
        {:error,
         {:unsupported_checkpoint_payload_encoding, row_index, Map.get(entry, "payload_encoding")}}

      not valid_sha256?(Map.get(entry, "payload_sha256")) ->
        {:error, {:checkpoint_entry_invalid_payload_hash, row_index}}

      not is_binary(Map.get(entry, "payload")) ->
        {:error, {:checkpoint_entry_invalid_payload, row_index}}

      true ->
        decode_and_validate_entry(entry, row_index, expected_row)
    end
  end

  defp validate_checkpoint_entry(_entry, row_index, _scenario_rows, _seen),
    do: {:error, {:invalid_checkpoint_entry, row_index}}

  defp decode_and_validate_entry(entry, row_index, expected_row) do
    with {:ok, payload} <- decode_payload(Map.fetch!(entry, "payload"), row_index),
         :ok <- validate_payload_hash(payload, Map.fetch!(entry, "payload_sha256"), row_index),
         {:ok, result} <- decode_result(payload, row_index),
         :ok <- validate_decoded_result(result, expected_row, row_index) do
      {:ok, result}
    end
  end

  defp decode_payload(payload, row_index) do
    case Base.decode64(payload) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, {:checkpoint_entry_invalid_base64, row_index}}
    end
  end

  defp validate_payload_hash(payload, actual, row_index) do
    expected = sha256(payload)

    if actual == expected do
      :ok
    else
      {:error, {:checkpoint_entry_hash_mismatch, row_index, expected, actual}}
    end
  end

  defp decode_result(payload, row_index) do
    case :erlang.binary_to_term(payload, [:safe]) do
      %ScenarioRunner.Result{} = result -> {:ok, result}
      _other -> {:error, {:checkpoint_entry_invalid_result, row_index}}
    end
  rescue
    error ->
      {:error, {:checkpoint_entry_invalid_term, row_index, Exception.message(error)}}
  end

  defp validate_decoded_result(result, expected_row, row_index) do
    expected_index = Map.fetch!(expected_row, "scenario_index")
    expected_id = Map.fetch!(expected_row, "scenario_id")

    cond do
      result.scenario_index != expected_index ->
        {:error,
         {:checkpoint_payload_index_mismatch, row_index, expected_index, result.scenario_index}}

      identity(result.scenario_id) != expected_id ->
        {:error,
         {:checkpoint_payload_scenario_id_mismatch, row_index, expected_id,
          identity(result.scenario_id)}}

      result.status == :ok and is_nil(result.value) ->
        {:error, {:checkpoint_payload_missing_value, row_index}}

      result.status == :error and is_nil(result.error) ->
        {:error, {:checkpoint_payload_missing_error, row_index}}

      result.status not in [:ok, :error] ->
        {:error, {:checkpoint_payload_invalid_status, row_index, result.status}}

      true ->
        :ok
    end
  end

  defp seal_checkpoint(checkpoint) do
    body = Map.delete(checkpoint, "content_sha256")
    Map.put(body, "content_sha256", term_sha256(body))
  end

  defp atomic_write(
         path,
         checkpoint,
         publication_mode \\ :replace,
         initial_publish_test_hook \\ nil
       ) do
    directory = Path.dirname(path)
    :ok = File.mkdir_p(directory)

    temporary_path =
      path <>
        ".tmp-" <>
        Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)

    json = checkpoint |> :json.encode() |> IO.iodata_to_binary()

    operation_result =
      try do
        with :ok <- write_and_sync_temporary(temporary_path, json <> "\n"),
             :ok <-
               invoke_initial_publish_test_hook(
                 publication_mode,
                 initial_publish_test_hook,
                 path
               ),
             :ok <- publish_temporary(temporary_path, path, publication_mode) do
          :ok
        end
      rescue
        error -> {:error, {:exception, Exception.message(error)}}
      catch
        kind, reason -> {:error, {kind, reason}}
      end

    publication_result =
      case operation_result do
        :ok ->
          :ok

        {:error, {:checkpoint_already_exists, _path} = reason} ->
          {:error, reason}

        {:error, reason} ->
          {:error, %{reason: :checkpoint_write_error, path: path, error: reason}}
      end

    cleanup_result = File.rm(temporary_path)

    case {publication_result, cleanup_result} do
      {result, :ok} ->
        result

      {result, {:error, :enoent}} ->
        result

      {{:error, _reason} = error, {:error, _cleanup_reason}} ->
        error

      {:ok, {:error, cleanup_reason}} ->
        {:error,
         %{
           reason: :checkpoint_write_error,
           path: path,
           error: {:temporary_cleanup_failed, cleanup_reason}
         }}
    end
  end

  defp write_and_sync_temporary(path, contents) do
    case File.open(path, [:write, :binary, :exclusive]) do
      {:ok, file} ->
        try do
          with :ok <- IO.binwrite(file, contents),
               :ok <- :file.sync(file) do
            :ok
          end
        after
          File.close(file)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp invoke_initial_publish_test_hook(:replace, _test_hook, _path), do: :ok

  defp invoke_initial_publish_test_hook(:create, test_hook, path) do
    invoke_test_hook(test_hook, %{
      schema_contract: @schema_contract,
      checkpoint_path: path,
      publication_mode: :create,
      temporary_file_synced: true
    })
  end

  defp publish_temporary(temporary_path, path, :replace),
    do: File.rename(temporary_path, path)

  defp publish_temporary(temporary_path, path, :create) do
    case File.ln(temporary_path, path) do
      :ok -> :ok
      {:error, :eexist} -> {:error, {:checkpoint_already_exists, path}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp file_sha256(path) do
    case File.read(path) do
      {:ok, contents} -> {:ok, sha256(contents)}
      {:error, reason} -> {:error, %{reason: :checkpoint_read_error, path: path, error: reason}}
    end
  end

  defp file_sha256!(path) do
    {:ok, digest} = file_sha256(path)
    digest
  end

  defp term_sha256(term) do
    term
    |> :erlang.term_to_binary([:deterministic])
    |> sha256()
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  defp valid_sha256?(value), do: is_binary(value) and Regex.match?(@hash_pattern, value)

  defp identity(value) when is_atom(value), do: Atom.to_string(value)
  defp identity(value) when is_binary(value), do: value
  defp identity(value), do: to_string(value)
end
