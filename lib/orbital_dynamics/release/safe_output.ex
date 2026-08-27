defmodule OrbitalDynamics.Release.SafeOutput do
  @moduledoc """
  Safe per-file publication for release and export artifacts.

  The caller-selected destination path is preserved. Publication is scoped to one
  file at a time: multi-file exports still publish each file independently.

  This helper is designed for cooperative local filesystems and single-writer
  export flows. It does not hold anchored directory handles and does not claim
  protection against hostile concurrent ancestor or target swaps.

  Root-level system directory aliases are admitted only through a closed,
  root-owned, group/world-non-writable, direct readlink rule. The concrete
  built-in alias is the macOS `/var` to `/private/var` temp-root alias.
  """

  import Bitwise, only: [band: 2]

  @max_path_bytes 4096
  @max_path_segment_bytes 255
  @max_content_bytes 32 * 1024 * 1024
  @max_content_depth 64
  @max_content_nodes 250_000
  @group_or_world_write_bits 0o022
  @trusted_system_directory_aliases %{"/var" => "/private/var"}
  @temp_prefix ".orbital_dynamics-safe-output-"
  @temp_suffix ".tmp"

  @doc """
  Writes bytes to a caller-selected output path through a same-directory temp file.

  Existing regular files may be replaced. Existing symlinks, symlink ancestors,
  directories, devices, malformed paths, and content values outside the bounded
  iodata envelope fail before the destination is opened. Failed parent creation,
  temp open, temp write, or rename leaves the destination unchanged. Owned-temp
  cleanup is attempted; cleanup failures are returned as typed errors and may
  leave residue. The only symlink ancestor exception is the closed trusted
  root-level system directory alias rule described in the module docs.
  """
  def write(path, iodata) do
    write_with_control(path, iodata, default_control())
  end

  @doc """
  Bang variant of `write/2`.

  Invalid or unsafe export destinations raise `ArgumentError`. That exception
  class is deliberate hardening for CLI export paths that previously surfaced
  raw filesystem exceptions.
  """
  def write!(path, iodata) do
    case write(path, iodata) do
      {:ok, ^path} ->
        path

      {:error, reason} ->
        raise ArgumentError, "safe output write failed: #{format_reason(reason)}"
    end
  end

  if Mix.env() == :test do
    @doc false
    def __test_write__(path, iodata, control) do
      with {:ok, control} <- test_control(control) do
        write_with_control(path, iodata, control)
      end
    end

    @doc false
    def __test_temporary_path__(path) when is_binary(path), do: temporary_path(path)
  end

  defp write_with_control(path, iodata, control) do
    with {:ok, admitted_path} <- admit_path(path),
         {:ok, bytes} <- admit_iodata(iodata),
         {:ok, temporary_path} <- temporary_path(admitted_path),
         :ok <- prepare_destination(admitted_path, temporary_path, control) do
      publish(admitted_path, temporary_path, bytes, control)
    end
  end

  defp admit_path(path) when is_binary(path) do
    cond do
      path == "" ->
        {:error, {:invalid_path, :empty}}

      byte_size(path) > @max_path_bytes ->
        {:error, {:invalid_path, {:too_long, byte_size(path), @max_path_bytes}}}

      not String.valid?(path) ->
        {:error, {:invalid_path, :invalid_utf8}}

      String.contains?(path, <<0>>) ->
        {:error, {:invalid_path, :nul_byte}}

      String.ends_with?(path, "/") ->
        {:error, {:invalid_path, :trailing_separator}}

      Path.basename(path) in [".", "..", "/"] ->
        {:error, {:invalid_path, :unsupported_target}}

      true ->
        admit_path_segments(path)
    end
  end

  defp admit_path(_path), do: {:error, {:invalid_path, :not_binary}}

  defp admit_path_segments(path) do
    path
    |> String.split("/", trim: false)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce_while({:ok, path}, fn segment, _result ->
      cond do
        segment == ".." ->
          {:halt, {:error, {:invalid_path_segment, "..", :parent_traversal}}}

        byte_size(segment) > @max_path_segment_bytes ->
          {:halt,
           {:error,
            {:invalid_path_segment, segment,
             {:too_long, byte_size(segment), @max_path_segment_bytes}}}}

        true ->
          {:cont, {:ok, path}}
      end
    end)
  end

  defp admit_iodata(iodata) when is_binary(iodata) or is_list(iodata) do
    case collect_iodata(iodata, 0, %{bytes: 0, nodes: 0, chunks: []}) do
      {:ok, %{chunks: chunks}} ->
        {:ok, IO.iodata_to_binary(Enum.reverse(chunks))}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp admit_iodata(iodata) do
    {:error, {:invalid_contents, {:unsupported_term, term_type(iodata)}}}
  end

  defp collect_iodata(_iodata, depth, _acc) when depth > @max_content_depth do
    {:error, {:resource_limit_exceeded, :content_depth, depth, @max_content_depth}}
  end

  defp collect_iodata(iodata, depth, acc) when is_list(iodata) do
    collect_iodata_list(iodata, depth, acc)
  end

  defp collect_iodata(iodata, _depth, acc) when is_binary(iodata) do
    with {:ok, acc} <- count_content_node(acc) do
      add_binary_chunk(iodata, acc)
    end
  end

  defp collect_iodata(iodata, _depth, acc) when is_integer(iodata) and iodata in 0..255 do
    with {:ok, acc} <- count_content_node(acc),
         {:ok, acc} <- add_content_bytes(1, acc) do
      {:ok, %{acc | chunks: [<<iodata>> | acc.chunks]}}
    end
  end

  defp collect_iodata(iodata, _depth, _acc) when is_integer(iodata) do
    {:error, {:invalid_contents, {:byte_out_of_range, iodata}}}
  end

  defp collect_iodata(iodata, _depth, _acc) do
    {:error, {:invalid_contents, {:unsupported_term, term_type(iodata)}}}
  end

  defp collect_iodata_list([], _depth, acc), do: {:ok, acc}

  defp collect_iodata_list([head | tail], depth, acc) do
    with {:ok, acc} <- count_content_node(acc),
         {:ok, acc} <- collect_iodata(head, depth + 1, acc) do
      collect_iodata_tail(tail, depth, acc)
    end
  end

  defp collect_iodata_tail([], _depth, acc), do: {:ok, acc}

  defp collect_iodata_tail(tail, depth, acc) when is_binary(tail) do
    collect_iodata(tail, depth + 1, acc)
  end

  defp collect_iodata_tail(tail, depth, acc) when is_list(tail) do
    collect_iodata_list(tail, depth, acc)
  end

  defp collect_iodata_tail(_tail, _depth, _acc) do
    {:error, {:invalid_contents, :improper_iodata}}
  end

  defp count_content_node(acc) do
    nodes = acc.nodes + 1

    if nodes > @max_content_nodes do
      {:error, {:resource_limit_exceeded, :content_nodes, nodes, @max_content_nodes}}
    else
      {:ok, %{acc | nodes: nodes}}
    end
  end

  defp add_binary_chunk(binary, acc) do
    with {:ok, acc} <- add_content_bytes(byte_size(binary), acc) do
      {:ok, %{acc | chunks: [binary | acc.chunks]}}
    end
  end

  defp add_content_bytes(size, acc) do
    bytes = acc.bytes + size

    if bytes > @max_content_bytes do
      {:error, {:resource_limit_exceeded, :content_bytes, bytes, @max_content_bytes}}
    else
      {:ok, %{acc | bytes: bytes}}
    end
  end

  defp temporary_path(path) do
    hash =
      :erlang.md5(path)
      |> Base.encode16(case: :lower)

    {:ok, Path.join(Path.dirname(path), @temp_prefix <> hash <> @temp_suffix)}
  end

  defp prepare_destination(path, temporary_path, control) do
    parent = Path.dirname(path)

    with :ok <- reject_existing_ancestor_ambiguity(parent, control),
         :ok <- mkdir_parent(parent, control),
         :ok <- reject_existing_ancestor_ambiguity(parent, control),
         :ok <- require_parent_directory(parent, control),
         :ok <- admit_target(path, control),
         :ok <- reject_temporary_collision(temporary_path, control) do
      :ok
    end
  end

  defp mkdir_parent(parent, control) do
    case control.mkdir_p.(parent) do
      :ok -> :ok
      {:error, reason} -> {:error, {:parent_create_failed, parent, reason}}
      other -> {:error, {:parent_create_failed, parent, {:unexpected_result, other}}}
    end
  end

  defp require_parent_directory(parent, control) do
    case control.lstat.(parent) do
      {:ok, %File.Stat{type: :directory}} ->
        :ok

      {:ok, %File.Stat{type: :symlink}} ->
        admit_trusted_ancestor_alias(parent, control)

      {:ok, %File.Stat{type: type}} ->
        {:error, {:unsupported_ancestor, parent, type}}

      {:error, reason} ->
        {:error, {:parent_stat_failed, parent, reason}}

      other ->
        {:error, {:parent_stat_failed, parent, {:unexpected_result, other}}}
    end
  end

  defp reject_existing_ancestor_ambiguity(parent, control) do
    parent
    |> ancestor_paths()
    |> Enum.reduce_while(:ok, fn ancestor, :ok ->
      case control.lstat.(ancestor) do
        {:ok, %File.Stat{type: :directory}} ->
          {:cont, :ok}

        {:ok, %File.Stat{type: :symlink}} ->
          case admit_trusted_ancestor_alias(ancestor, control) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end

        {:ok, %File.Stat{type: type}} ->
          {:halt, {:error, {:unsupported_ancestor, ancestor, type}}}

        {:error, :enoent} ->
          {:halt, :ok}

        {:error, reason} ->
          {:halt, {:error, {:ancestor_stat_failed, ancestor, reason}}}

        other ->
          {:halt, {:error, {:ancestor_stat_failed, ancestor, {:unexpected_result, other}}}}
      end
    end)
  end

  defp ancestor_paths("."), do: []

  defp ancestor_paths(parent) do
    case Path.split(parent) do
      ["/"] ->
        []

      ["/" | segments] ->
        segments
        |> Enum.reject(&(&1 == "."))
        |> Enum.scan("/", &Path.join(&2, &1))

      segments ->
        segments
        |> Enum.reject(&(&1 == "."))
        |> Enum.scan(&Path.join(&2, &1))
    end
  end

  defp admit_trusted_ancestor_alias(alias_path, control) do
    with {:ok, expected_target} <- trusted_system_alias_target(alias_path),
         {:ok, alias_stat} <- trusted_alias_lstat(alias_path, control),
         :ok <- require_trusted_alias_link_stat(alias_path, alias_stat),
         :ok <- require_trusted_alias_parent(alias_path, control),
         {:ok, resolved_target} <- read_trusted_alias_target(alias_path, control),
         :ok <- require_expected_trusted_alias_target(resolved_target, expected_target),
         :ok <- require_trusted_alias_target_directories(resolved_target, control) do
      :ok
    else
      :not_trusted_alias ->
        {:error, {:unsafe_symlink, :ancestor, alias_path}}

      {:error, reason} ->
        {:error, {:unsafe_symlink, :ancestor, alias_path, reason}}
    end
  end

  defp trusted_system_alias_target(alias_path) do
    case {Path.dirname(alias_path), Map.fetch(@trusted_system_directory_aliases, alias_path)} do
      {"/", {:ok, target}} -> {:ok, target}
      _other -> :not_trusted_alias
    end
  end

  defp trusted_alias_lstat(path, control) do
    case control.lstat.(path) do
      {:ok, %File.Stat{type: :symlink} = stat} ->
        {:ok, stat}

      {:ok, %File.Stat{type: type}} ->
        {:error, {:trusted_alias_not_link, path, type}}

      {:error, reason} ->
        {:error, {:trusted_alias_lstat_failed, path, reason}}

      other ->
        {:error, {:trusted_alias_lstat_failed, path, {:unexpected_result, other}}}
    end
  end

  defp require_trusted_alias_parent(alias_path, control) do
    parent = Path.dirname(alias_path)

    case trusted_alias_directory_lstat(parent, control) do
      {:ok, stat} -> require_root_owned_non_writable(parent, stat, :trusted_alias_parent)
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_trusted_alias_target(alias_path, control) do
    with {:ok, target} <- read_trusted_alias(alias_path, control),
         {:ok, target_path} <- trusted_alias_target_path(alias_path, target) do
      {:ok, target_path}
    end
  end

  defp read_trusted_alias(path, control) do
    case control.read_link.(path) do
      {:ok, target} when is_binary(target) ->
        {:ok, target}

      {:ok, target} ->
        {:error, {:trusted_alias_readlink_failed, path, {:unexpected_result, target}}}

      {:error, reason} ->
        {:error, {:trusted_alias_readlink_failed, path, reason}}

      other ->
        {:error, {:trusted_alias_readlink_failed, path, {:unexpected_result, other}}}
    end
  end

  defp trusted_alias_target_path(link_path, target) do
    cond do
      target == "" ->
        {:error, {:trusted_alias_target_path_invalid, target, :empty}}

      byte_size(target) > @max_path_bytes ->
        {:error, {:trusted_alias_target_path_invalid, target, :too_long}}

      not String.valid?(target) ->
        {:error, {:trusted_alias_target_path_invalid, target, :invalid_utf8}}

      String.contains?(target, <<0>>) ->
        {:error, {:trusted_alias_target_path_invalid, target, :nul_byte}}

      trusted_alias_target_has_parent_segment?(target) ->
        {:error, {:trusted_alias_relative_escape, target}}

      true ->
        target_path =
          case Path.type(target) do
            :absolute -> Path.expand(target)
            :relative -> Path.expand(target, Path.dirname(link_path))
          end

        with :ok <- admit_trusted_alias_target_path_bounds(target_path) do
          {:ok, target_path}
        end
    end
  end

  defp trusted_alias_target_has_parent_segment?(target) do
    target
    |> String.split("/", trim: false)
    |> Enum.any?(&(&1 == ".."))
  end

  defp admit_trusted_alias_target_path_bounds(path) do
    case admit_path(path) do
      {:ok, ^path} -> :ok
      {:error, reason} -> {:error, {:trusted_alias_target_path_invalid, path, reason}}
    end
  end

  defp require_expected_trusted_alias_target(resolved_target, expected_target) do
    if resolved_target == expected_target do
      :ok
    else
      {:error, {:trusted_alias_target_mismatch, resolved_target, expected_target}}
    end
  end

  defp require_trusted_alias_target_directories(target_path, control) do
    target_path
    |> ancestor_paths()
    |> Enum.reduce_while(:ok, fn directory, :ok ->
      case trusted_alias_directory_lstat(directory, control) do
        {:ok, stat} ->
          case require_root_owned_non_writable(directory, stat, :trusted_alias_target_directory) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp trusted_alias_directory_lstat(directory, control) do
    case control.lstat.(directory) do
      {:ok, %File.Stat{type: :directory}} ->
        trusted_alias_directory_stat(directory, control)

      {:ok, %File.Stat{type: :symlink}} ->
        {:error, {:trusted_alias_target_directory_symlink, directory}}

      {:ok, %File.Stat{type: type}} ->
        {:error, {:trusted_alias_target_directory_not_directory, directory, type}}

      {:error, reason} ->
        {:error, {:trusted_alias_target_directory_lstat_failed, directory, reason}}

      other ->
        {:error,
         {:trusted_alias_target_directory_lstat_failed, directory, {:unexpected_result, other}}}
    end
  end

  defp trusted_alias_directory_stat(directory, control) do
    case control.stat.(directory) do
      {:ok, %File.Stat{type: :directory} = stat} ->
        {:ok, stat}

      {:ok, %File.Stat{type: type}} ->
        {:error, {:trusted_alias_target_directory_not_directory, directory, type}}

      {:error, reason} ->
        {:error, {:trusted_alias_target_directory_stat_failed, directory, reason}}

      other ->
        {:error,
         {:trusted_alias_target_directory_stat_failed, directory, {:unexpected_result, other}}}
    end
  end

  defp require_trusted_alias_link_stat(path, stat) do
    require_root_owned_non_writable(path, stat, :trusted_alias_link)
  end

  defp require_root_owned_non_writable(path, %File.Stat{uid: 0, mode: mode}, _kind)
       when is_integer(mode) do
    if band(mode, @group_or_world_write_bits) == 0 do
      :ok
    else
      {:error, {:trusted_alias_writable, path, mode}}
    end
  end

  defp require_root_owned_non_writable(path, %File.Stat{uid: 0, mode: mode}, _kind) do
    {:error, {:trusted_alias_mode_invalid, path, mode}}
  end

  defp require_root_owned_non_writable(path, %File.Stat{uid: uid}, _kind) do
    {:error, {:trusted_alias_not_root_owned, path, uid}}
  end

  defp admit_target(path, control) do
    case control.lstat.(path) do
      {:ok, %File.Stat{type: :regular}} ->
        :ok

      {:ok, %File.Stat{type: :symlink}} ->
        {:error, {:unsafe_symlink, :target, path}}

      {:ok, %File.Stat{type: type}} ->
        {:error, {:unsupported_target, path, type}}

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        {:error, {:target_stat_failed, path, reason}}

      other ->
        {:error, {:target_stat_failed, path, {:unexpected_result, other}}}
    end
  end

  defp reject_temporary_collision(temporary_path, control) do
    case control.lstat.(temporary_path) do
      {:error, :enoent} -> :ok
      {:ok, %File.Stat{}} -> {:error, {:temporary_path_exists, temporary_path}}
      {:error, reason} -> {:error, {:temporary_stat_failed, temporary_path, reason}}
      other -> {:error, {:temporary_stat_failed, temporary_path, {:unexpected_result, other}}}
    end
  end

  defp publish(path, temporary_path, bytes, control) do
    case write_temporary(temporary_path, bytes, control) do
      :ok ->
        case control.after_temporary_write.(path, temporary_path) do
          :ok ->
            rename_temporary(path, temporary_path, control)

          {:error, reason} ->
            cleanup_temporary(
              temporary_path,
              control,
              {:after_temporary_write_failed, temporary_path, reason}
            )

          other ->
            cleanup_temporary(
              temporary_path,
              control,
              {:after_temporary_write_failed, temporary_path, {:unexpected_result, other}}
            )
        end

      {:error, reason, true} ->
        cleanup_temporary(temporary_path, control, reason)

      {:error, reason, false} ->
        {:error, reason}
    end
  end

  defp write_temporary(temporary_path, bytes, control) do
    case control.open.(temporary_path, [:write, :binary, :exclusive]) do
      {:ok, io_device} ->
        write_result = control.binwrite.(io_device, bytes)
        close_result = control.close.(io_device)
        write_temporary_result(temporary_path, write_result, close_result)

      {:error, :eexist} ->
        {:error, {:temporary_path_exists, temporary_path}, false}

      {:error, reason} ->
        {:error, {:write_failed, temporary_path, reason}, false}

      other ->
        {:error, {:write_failed, temporary_path, {:unexpected_result, other}}, false}
    end
  end

  defp write_temporary_result(_temporary_path, :ok, :ok), do: :ok

  defp write_temporary_result(temporary_path, {:error, reason}, _close_result),
    do: {:error, {:write_failed, temporary_path, reason}, true}

  defp write_temporary_result(temporary_path, :ok, {:error, reason}),
    do: {:error, {:write_failed, temporary_path, reason}, true}

  defp write_temporary_result(temporary_path, write_result, _close_result),
    do: {:error, {:write_failed, temporary_path, {:unexpected_result, write_result}}, true}

  defp rename_temporary(path, temporary_path, control) do
    with :ok <- admit_target(path, control) do
      case control.rename.(temporary_path, path) do
        :ok ->
          {:ok, path}

        {:error, reason} ->
          cleanup_temporary(
            temporary_path,
            control,
            {:rename_failed, temporary_path, path, reason}
          )

        other ->
          cleanup_temporary(
            temporary_path,
            control,
            {:rename_failed, temporary_path, path, {:unexpected_result, other}}
          )
      end
    else
      {:error, reason} ->
        cleanup_temporary(temporary_path, control, reason)
    end
  end

  defp cleanup_temporary(temporary_path, control, original_reason) do
    case control.rm.(temporary_path) do
      :ok ->
        {:error, original_reason}

      {:error, :enoent} ->
        {:error, original_reason}

      {:error, reason} ->
        {:error, {:temporary_cleanup_failed, temporary_path, reason, original_reason}}

      other ->
        {:error,
         {:temporary_cleanup_failed, temporary_path, {:unexpected_result, other}, original_reason}}
    end
  end

  defp default_control do
    %{
      after_temporary_write: fn _path, _temporary_path -> :ok end,
      binwrite: &IO.binwrite/2,
      close: &File.close/1,
      lstat: &File.lstat/1,
      mkdir_p: &File.mkdir_p/1,
      open: &File.open/2,
      read_link: &File.read_link/1,
      rename: &File.rename/2,
      stat: &File.stat/1,
      rm: &File.rm/1
    }
  end

  if Mix.env() == :test do
    @test_control_callbacks [
      after_temporary_write: 2,
      binwrite: 2,
      close: 1,
      lstat: 1,
      mkdir_p: 1,
      open: 2,
      read_link: 1,
      rename: 2,
      stat: 1,
      rm: 1
    ]

    defp test_control(control) when is_map(control) do
      allowed_keys = Keyword.keys(@test_control_callbacks)
      unknown_keys = control |> Map.keys() |> Kernel.--(allowed_keys) |> Enum.sort()

      cond do
        unknown_keys != [] ->
          {:error, {:invalid_test_control, {:unknown_keys, unknown_keys}}}

        true ->
          validate_test_control_callbacks(control, @test_control_callbacks)
      end
    end

    defp test_control(_control), do: {:error, {:invalid_test_control, :not_map}}

    defp validate_test_control_callbacks(control, callbacks) do
      Enum.reduce_while(callbacks, {:ok, default_control()}, fn {key, arity}, {:ok, acc} ->
        case Map.fetch(control, key) do
          {:ok, callback} when is_function(callback, arity) ->
            {:cont, {:ok, Map.put(acc, key, callback)}}

          {:ok, _callback} ->
            {:halt, {:error, {:invalid_test_control, key, {:expected_fun_arity, arity}}}}

          :error ->
            {:cont, {:ok, acc}}
        end
      end)
    end
  end

  defp term_type(term) when is_atom(term), do: :atom
  defp term_type(term) when is_bitstring(term), do: :bitstring
  defp term_type(term) when is_float(term), do: :float
  defp term_type(term) when is_function(term), do: :function
  defp term_type(term) when is_integer(term), do: :integer
  defp term_type(term) when is_map(term), do: :map
  defp term_type(term) when is_pid(term), do: :pid
  defp term_type(term) when is_port(term), do: :port
  defp term_type(term) when is_reference(term), do: :reference
  defp term_type(term) when is_tuple(term), do: :tuple
  defp term_type(_term), do: :unknown

  defp format_reason(reason), do: inspect(reason)
end
