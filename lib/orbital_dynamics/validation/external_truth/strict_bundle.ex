defmodule OrbitalDynamics.Validation.ExternalTruth.StrictBundle do
  @moduledoc false

  @sha256_regex ~r/\A[0-9a-f]{64}\z/
  @source_manifest_regex ~r/\A([0-9a-f]{64})  ([^\r\n]+)\z/

  def load(root, expectations) when is_binary(root) and is_map(expectations) do
    with {:ok, root} <- validate_root(root),
         {:ok, manifest_bytes} <-
           read_verified_file(
             root,
             "manifest.json",
             expectations.manifest_sha256,
             expectations.manifest_byte_count
           ),
         {:ok, manifest} <- decode_json_strict(manifest_bytes),
         :ok <- validate_identity_declarations(manifest, expectations),
         {:ok, source_manifest_bytes} <-
           read_verified_file(
             root,
             "source-manifest.sha256",
             expectations.source_manifest_sha256,
             expectations.source_manifest_byte_count
           ),
         {:ok, source_entries} <- parse_source_manifest(source_manifest_bytes),
         :ok <- validate_source_entries(source_entries, expectations.source_paths),
         :ok <- verify_source_files(root, source_entries),
         {:ok, config_bytes} <- read_regular_file(root, "case.properties"),
         {:ok, config} <- parse_properties_strict(config_bytes),
         {:ok, dependency_bytes} <- read_regular_file(root, "dependencies.lock"),
         {:ok, dependencies} <- parse_dependency_lock(dependency_bytes),
         {:ok, reference_bytes} <-
           read_verified_file(
             root,
             "reference-output.json",
             expectations.result_sha256,
             expectations.result_byte_count
           ),
         {:ok, reference} <- decode_json_strict(reference_bytes) do
      {:ok,
       %{
         root: root,
         manifest: manifest,
         manifest_bytes: manifest_bytes,
         source_manifest_entries: source_entries,
         source_manifest_bytes: source_manifest_bytes,
         config: config,
         config_bytes: config_bytes,
         dependencies: dependencies,
         dependency_bytes: dependency_bytes,
         reference: reference,
         reference_bytes: reference_bytes
       }}
    end
  end

  def load(_root, _expectations), do: {:error, {:invalid_bundle, :invalid_load_arguments}}

  @doc false
  def decode_json_strict(bytes) when is_binary(bytes) do
    object_push = fn key, value, entries ->
      if Enum.any?(entries, fn {existing_key, _value} -> existing_key == key end) do
        throw({:duplicate_json_key, key})
      else
        [{key, value} | entries]
      end
    end

    try do
      case :json.decode(bytes, :ok, %{object_push: object_push}) do
        {value, :ok, rest} ->
          if String.trim(rest) == "" do
            {:ok, value}
          else
            {:error, {:invalid_json, :trailing_bytes}}
          end
      end
    rescue
      error -> {:error, {:invalid_json, Exception.message(error)}}
    catch
      {:duplicate_json_key, key} -> {:error, {:duplicate_json_key, key}}
      kind, reason -> {:error, {:invalid_json, {kind, reason}}}
    end
  end

  def decode_json_strict(_bytes), do: {:error, {:invalid_json, :not_binary}}

  @doc false
  def parse_source_manifest(bytes) when is_binary(bytes) do
    with {:ok, lines} <- non_empty_lines(bytes, :source_manifest),
         {:ok, entries} <- parse_source_manifest_lines(lines),
         :ok <- reject_duplicate_values(entries, & &1.path, :duplicate_source_path) do
      {:ok, entries}
    end
  end

  def parse_source_manifest(_bytes),
    do: {:error, {:invalid_bundle, :invalid_source_manifest_bytes}}

  @doc false
  def parse_properties_strict(bytes) when is_binary(bytes) do
    with {:ok, lines} <- non_empty_lines(bytes, :properties),
         {:ok, entries} <- parse_property_lines(lines),
         :ok <- reject_duplicate_values(entries, &elem(&1, 0), :duplicate_config_key) do
      {:ok, Map.new(entries)}
    end
  end

  def parse_properties_strict(_bytes),
    do: {:error, {:invalid_bundle, :invalid_config_bytes}}

  @doc false
  def parse_dependency_lock(bytes) when is_binary(bytes) do
    with {:ok, lines} <- non_empty_lines(bytes, :dependency_lock),
         {:ok, entries} <- parse_dependency_lines(lines),
         :ok <- reject_duplicate_values(entries, & &1.filename, :duplicate_dependency_filename),
         :ok <- reject_duplicate_values(entries, & &1.url, :duplicate_dependency_url) do
      {:ok, entries}
    end
  end

  def parse_dependency_lock(_bytes),
    do: {:error, {:invalid_bundle, :invalid_dependency_lock_bytes}}

  defp validate_root(root) do
    root = Path.expand(root)

    cond do
      not File.dir?(root) -> {:error, {:invalid_bundle, :bundle_directory_not_found}}
      true -> {:ok, root}
    end
  end

  defp validate_identity_declarations(manifest, expectations) when is_map(manifest) do
    declarations = [
      {get_in(manifest, ["source_identity", "algorithm"]), "sha256", :source_algorithm},
      {get_in(manifest, ["source_identity", "manifest_path"]), "source-manifest.sha256",
       :source_manifest_path},
      {get_in(manifest, ["source_identity", "manifest_byte_count"]),
       expectations.source_manifest_byte_count, :source_manifest_byte_count},
      {get_in(manifest, ["source_identity", "sha256"]), expectations.source_manifest_sha256,
       :source_manifest_sha256},
      {get_in(manifest, ["result_identity", "algorithm"]), "sha256", :result_algorithm},
      {get_in(manifest, ["result_identity", "path"]), "reference-output.json", :result_path},
      {get_in(manifest, ["result_identity", "byte_count"]), expectations.result_byte_count,
       :result_byte_count},
      {get_in(manifest, ["result_identity", "sha256"]), expectations.result_sha256,
       :result_sha256}
    ]

    case Enum.find(declarations, fn {observed, expected, _field} -> observed != expected end) do
      nil -> :ok
      {observed, expected, field} -> integrity_error(field, expected, observed)
    end
  end

  defp validate_identity_declarations(_manifest, _expectations),
    do: {:error, {:invalid_bundle, :manifest_must_be_object}}

  defp read_verified_file(root, path, expected_sha256, expected_byte_count) do
    with true <- valid_sha256?(expected_sha256),
         {:ok, bytes} <- read_regular_file(root, path) do
      actual_sha256 = sha256(bytes)
      actual_byte_count = byte_size(bytes)

      cond do
        actual_sha256 != expected_sha256 ->
          integrity_error("#{path}.sha256", expected_sha256, actual_sha256)

        actual_byte_count != expected_byte_count ->
          integrity_error("#{path}.byte_count", expected_byte_count, actual_byte_count)

        true ->
          {:ok, bytes}
      end
    else
      false -> {:error, {:invalid_bundle, {:invalid_expected_sha256, path}}}
      {:error, _reason} = error -> error
    end
  end

  defp read_regular_file(root, relative_path) do
    with {:ok, path} <- safe_bundle_path(root, relative_path),
         {:ok, stat} <- File.lstat(path),
         true <- stat.type == :regular,
         {:ok, bytes} <- File.read(path) do
      {:ok, bytes}
    else
      false -> {:error, {:invalid_bundle, {:not_regular_file, relative_path}}}
      {:error, reason} -> {:error, {:invalid_bundle, {:file_error, relative_path, reason}}}
    end
  end

  defp safe_bundle_path(root, relative_path) when is_binary(relative_path) do
    expanded = Path.expand(relative_path, root)

    cond do
      Path.type(relative_path) != :relative ->
        {:error, {:invalid_bundle, {:absolute_source_path, relative_path}}}

      expanded == root ->
        {:error, {:invalid_bundle, {:invalid_source_path, relative_path}}}

      not String.starts_with?(expanded, root <> "/") ->
        {:error, {:invalid_bundle, {:source_path_escape, relative_path}}}

      true ->
        {:ok, expanded}
    end
  end

  defp safe_bundle_path(_root, relative_path),
    do: {:error, {:invalid_bundle, {:invalid_source_path, relative_path}}}

  defp parse_source_manifest_lines(lines) do
    reduce_lines(lines, fn line, line_number ->
      case Regex.run(@source_manifest_regex, line, capture: :all_but_first) do
        [sha256, path] ->
          if safe_relative_manifest_path?(path) do
            {:ok, %{sha256: sha256, path: path}}
          else
            {:error, {:invalid_bundle, {:unsafe_source_manifest_path, line_number, path}}}
          end

        _match ->
          {:error, {:invalid_bundle, {:malformed_source_manifest_line, line_number}}}
      end
    end)
  end

  defp parse_property_lines(lines) do
    reduce_lines(lines, fn line, line_number ->
      case :binary.split(line, "=", [:global]) do
        [key, value] when key != "" and value != "" ->
          if key == String.trim(key) and value == String.trim(value) do
            {:ok, {key, value}}
          else
            {:error, {:invalid_bundle, {:config_whitespace, line_number}}}
          end

        _parts ->
          {:error, {:invalid_bundle, {:malformed_config_line, line_number}}}
      end
    end)
  end

  defp parse_dependency_lines(lines) do
    reduce_lines(lines, fn line, line_number ->
      case String.split(line, " ", trim: false) do
        [sha256, url, filename]
        when filename != "" and url != "" ->
          cond do
            not valid_sha256?(sha256) ->
              {:error, {:invalid_bundle, {:invalid_dependency_sha256, line_number}}}

            not String.starts_with?(url, "https://repo.maven.apache.org/maven2/") ->
              {:error, {:invalid_bundle, {:invalid_dependency_url, line_number}}}

            not safe_dependency_filename?(filename) ->
              {:error, {:invalid_bundle, {:invalid_dependency_filename, line_number}}}

            true ->
              {:ok, %{sha256: sha256, url: url, filename: filename}}
          end

        _parts ->
          {:error, {:invalid_bundle, {:malformed_dependency_line, line_number}}}
      end
    end)
  end

  defp reduce_lines(lines, parser) do
    lines
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {line, line_number}, {:ok, entries} ->
      case parser.(line, line_number) do
        {:ok, entry} -> {:cont, {:ok, [entry | entries]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      {:error, _reason} = error -> error
    end
  end

  defp non_empty_lines(bytes, kind) do
    if String.valid?(bytes) do
      lines = String.split(bytes, "\n", trim: false)
      lines = if List.last(lines) == "", do: List.delete_at(lines, -1), else: lines

      cond do
        lines == [] ->
          {:error, {:invalid_bundle, {kind, :empty}}}

        Enum.any?(lines, &(&1 == "")) ->
          {:error, {:invalid_bundle, {kind, :blank_line}}}

        Enum.any?(lines, &String.ends_with?(&1, "\r")) ->
          {:error, {:invalid_bundle, {kind, :non_lf_line_ending}}}

        true ->
          {:ok, lines}
      end
    else
      {:error, {:invalid_bundle, {kind, :invalid_utf8}}}
    end
  end

  defp reject_duplicate_values(entries, key_fun, reason) do
    values = Enum.map(entries, key_fun)

    case Enum.find(Enum.frequencies(values), fn {_value, count} -> count > 1 end) do
      nil -> :ok
      {value, _count} -> {:error, {:invalid_bundle, {reason, value}}}
    end
  end

  defp validate_source_entries(entries, expected_paths) do
    observed_paths = entries |> Enum.map(& &1.path) |> Enum.sort()
    expected_paths = Enum.sort(expected_paths)

    if observed_paths == expected_paths do
      :ok
    else
      integrity_error(:source_manifest_paths, expected_paths, observed_paths)
    end
  end

  defp verify_source_files(root, entries) do
    Enum.reduce_while(entries, :ok, fn entry, :ok ->
      case read_verified_file(root, entry.path, entry.sha256, source_file_size(root, entry.path)) do
        {:ok, _bytes} -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp source_file_size(root, relative_path) do
    with {:ok, path} <- safe_bundle_path(root, relative_path),
         {:ok, stat} <- File.lstat(path) do
      stat.size
    else
      _error -> -1
    end
  end

  defp safe_relative_manifest_path?(path) do
    path != "" and Path.type(path) == :relative and
      not Enum.member?(Path.split(path), "..") and
      not String.contains?(path, "\\")
  end

  defp safe_dependency_filename?(filename) do
    filename != "" and Path.basename(filename) == filename and
      not String.contains?(filename, ["/", "\\"])
  end

  defp valid_sha256?(value), do: is_binary(value) and Regex.match?(@sha256_regex, value)
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp integrity_error(field, expected, observed) do
    {:error, {:bundle_integrity_failed, field, expected, observed}}
  end
end
