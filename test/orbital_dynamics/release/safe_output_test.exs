defmodule OrbitalDynamics.Release.SafeOutputTest do
  use ExUnit.Case, async: false

  alias OrbitalDynamics.Release.SafeOutput

  test "exposes only seam-free production write arities" do
    assert function_exported?(SafeOutput, :write, 2)
    assert function_exported?(SafeOutput, :write!, 2)
    refute function_exported?(SafeOutput, :write, 3)
    refute function_exported?(SafeOutput, :write!, 3)

    assert function_exported?(SafeOutput, :__test_write__, 3)
    assert function_exported?(SafeOutput, :__test_temporary_path__, 1)
  end

  test "writes valid nested output and preserves caller-selected path and bytes" do
    root = tmp_root("valid_nested")
    output_path = Path.join([root, "schemas", "nested", "artifact.json"])

    on_exit(fn -> File.rm_rf(root) end)

    assert {:ok, ^output_path} = SafeOutput.write(output_path, ["{\"ok\":", ?t, "rue}\n"])
    assert File.read!(output_path) == ~s({"ok":true}\n)
    assert_no_temp_residue!(Path.dirname(output_path))
  end

  test "admits valid binary iodata tails" do
    root = tmp_root("binary_tail")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)

    assert {:ok, ^output_path} = SafeOutput.write(output_path, [?a, [?b] | "c\n"])
    assert File.read!(output_path) == "abc\n"
    assert_no_temp_residue!(root)
  end

  test "writes through the macOS System tmp root alias when present" do
    system_tmp_dir = System.tmp_dir!()

    case {String.starts_with?(system_tmp_dir, "/var/"), File.read_link("/var")} do
      {true, {:ok, target}} when target in ["private/var", "/private/var"] ->
        root =
          Path.join(
            system_tmp_dir,
            "orbital_dynamics_safe_output_macos_var_alias_#{System.unique_integer([:positive])}"
          )

        output_path = Path.join(root, "artifact.json")

        on_exit(fn -> File.rm_rf(root) end)

        assert {:ok, ^output_path} = SafeOutput.write(output_path, "bytes\n")
        assert File.read!(output_path) == "bytes\n"
        assert_no_temp_residue!(root)

      _other ->
        :ok
    end
  end

  test "replaces existing regular files" do
    root = tmp_root("replace")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(output_path, "stale\n")

    assert {:ok, ^output_path} = SafeOutput.write(output_path, "fresh\n")
    assert File.read!(output_path) == "fresh\n"
    assert_no_temp_residue!(root)
  end

  test "rejects malformed paths without creating output" do
    root = tmp_root("invalid_paths")
    output_path = Path.join(root, "artifact.json")
    long_segment = String.duplicate("a", 256)
    too_long_path = String.duplicate("a", 4097)

    on_exit(fn -> File.rm_rf(root) end)

    assert {:error, {:invalid_path, :not_binary}} = SafeOutput.write(:not_a_path, "bytes")
    assert {:error, {:invalid_path, :empty}} = SafeOutput.write("", "bytes")
    assert {:error, {:invalid_path, :invalid_utf8}} = SafeOutput.write(<<255>>, "bytes")

    assert {:error, {:invalid_path, :nul_byte}} =
             SafeOutput.write("bad" <> <<0>> <> "path", "bytes")

    assert {:error, {:invalid_path, :trailing_separator}} =
             SafeOutput.write(output_path <> "/", "bytes")

    assert {:error, {:invalid_path, {:too_long, 4097, 4096}}} =
             SafeOutput.write(too_long_path, "bytes")

    assert {:error, {:invalid_path_segment, "..", :parent_traversal}} =
             SafeOutput.write(root <> "/../escape.json", "bytes")

    assert {:error, {:invalid_path_segment, ^long_segment, {:too_long, 256, 255}}} =
             SafeOutput.write(Path.join(root, long_segment), "bytes")

    refute File.exists?(root)
  end

  test "rejects invalid contents without creating output" do
    root = tmp_root("invalid_contents")
    output_path = Path.join(root, "artifact.json")
    max_content_bytes = 32 * 1024 * 1024
    deep = Enum.reduce(1..65, "x", fn _depth, acc -> [acc] end)
    oversized = :binary.copy("x", max_content_bytes + 1)
    over_nodes = List.duplicate(?a, 250_001)

    on_exit(fn -> File.rm_rf(root) end)

    assert {:error, {:invalid_contents, {:unsupported_term, :atom}}} =
             SafeOutput.write(output_path, :not_bytes)

    assert {:error, {:invalid_contents, {:unsupported_term, :integer}}} =
             SafeOutput.write(output_path, ?a)

    assert {:error, {:invalid_contents, {:unsupported_term, :bitstring}}} =
             SafeOutput.write(output_path, <<1::1>>)

    assert {:error, {:invalid_contents, :improper_iodata}} =
             SafeOutput.write(output_path, ["bytes" | :not_a_binary_tail])

    assert {:error, {:invalid_contents, {:byte_out_of_range, 256}}} =
             SafeOutput.write(output_path, [256])

    assert {:error, {:invalid_contents, {:byte_out_of_range, -1}}} =
             SafeOutput.write(output_path, [-1])

    assert {:error, {:invalid_contents, {:unsupported_term, :function}}} =
             SafeOutput.write(output_path, fn -> :bad end)

    assert {:error, {:invalid_contents, {:unsupported_term, :map}}} =
             SafeOutput.write(output_path, %{bytes: "bad"})

    assert {:error, {:resource_limit_exceeded, :content_depth, depth, 64}} =
             SafeOutput.write(output_path, deep)

    assert depth > 64

    assert {:error, {:resource_limit_exceeded, :content_bytes, bytes, ^max_content_bytes}} =
             SafeOutput.write(output_path, oversized)

    assert bytes == max_content_bytes + 1

    assert {:error, {:resource_limit_exceeded, :content_nodes, nodes, 250_000}} =
             SafeOutput.write(output_path, over_nodes)

    assert nodes > 250_000
    refute File.exists?(root)
  end

  test "rejects target symlinks including broken links without writing through them" do
    root = tmp_root("target_symlink")
    real_path = Path.join(root, "real.json")
    symlink_path = Path.join(root, "linked.json")
    broken_symlink_path = Path.join(root, "broken.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(real_path, "original\n")
    File.ln_s!(real_path, symlink_path)
    File.ln_s!(Path.join(root, "missing.json"), broken_symlink_path)

    assert {:error, {:unsafe_symlink, :target, ^symlink_path}} =
             SafeOutput.write(symlink_path, "replacement\n")

    assert {:error, {:unsafe_symlink, :target, ^broken_symlink_path}} =
             SafeOutput.write(broken_symlink_path, "replacement\n")

    assert File.read!(real_path) == "original\n"
    assert_no_temp_residue!(root)
  end

  test "rejects symlink ancestors including broken links without writing through them" do
    root = tmp_root("ancestor_symlink")
    real_parent = Path.join(root, "real_parent")
    symlink_parent = Path.join(root, "linked_parent")
    broken_symlink_parent = Path.join(root, "broken_parent")
    output_path = Path.join(symlink_parent, "artifact.json")
    broken_output_path = Path.join(broken_symlink_parent, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(real_parent)
    File.ln_s!(real_parent, symlink_parent)
    File.ln_s!(Path.join(root, "missing_parent"), broken_symlink_parent)

    assert {:error, {:unsafe_symlink, :ancestor, ^symlink_parent}} =
             SafeOutput.write(output_path, "bytes\n")

    assert {:error, {:unsafe_symlink, :ancestor, ^broken_symlink_parent}} =
             SafeOutput.write(broken_output_path, "bytes\n")

    refute File.exists?(Path.join(real_parent, "artifact.json"))
    assert_no_temp_residue!(real_parent)
  end

  test "trusted root alias rejects path-only authority and unsafe resolution" do
    output_path = "/var/folders/test/artifact.json"

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var", {:trusted_alias_not_root_owned, "/var", 501}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 lstat_results: %{"/var" => {:ok, symlink_stat(uid: 501)}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var", {:trusted_alias_writable, "/var", _mode}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 lstat_results: %{"/var" => {:ok, symlink_stat(mode: 0o775)}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var", {:trusted_alias_mode_invalid, "/var", nil}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 lstat_results: %{"/var" => {:ok, symlink_stat(mode: nil)}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var", {:trusted_alias_not_root_owned, "/", 501}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 stat_results: %{"/" => {:ok, directory_stat(uid: 501)}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_mismatch, "/private/tmp", "/private/var"}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 read_link_results: %{"/var" => {:ok, "private/tmp"}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_directory_symlink, "/private"}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 lstat_results: %{"/private" => {:ok, symlink_stat()}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var", {:trusted_alias_writable, "/private", _mode}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 stat_results: %{"/private" => {:ok, directory_stat(mode: 0o777)}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_writable, "/private/var", _target_mode}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 stat_results: %{"/private/var" => {:ok, directory_stat(mode: 0o777)}}
               })
             )
  end

  test "trusted root alias rejects read errors, broken links, relative escapes, and mismatches" do
    output_path = "/var/folders/test/artifact.json"
    oversized_link_target = "/" <> String.duplicate("a", 4097)

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_readlink_failed, "/var", :eacces}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 read_link_results: %{"/var" => {:error, :eacces}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_directory_lstat_failed, "/private/var", :enoent}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 lstat_results: %{"/private/var" => {:error, :enoent}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_directory_stat_failed, "/private/var", :eacces}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 stat_results: %{"/private/var" => {:error, :eacces}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_relative_escape, "../private/var"}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 read_link_results: %{"/var" => {:ok, "../private/var"}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_path_invalid, ^oversized_link_target, :too_long}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 read_link_results: %{"/var" => {:ok, oversized_link_target}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_mismatch, "/var", "/private/var"}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               fake_var_alias_control(%{
                 read_link_results: %{"/var" => {:ok, "/var"}}
               })
             )

    assert {:error,
            {:unsafe_symlink, :ancestor, "/var",
             {:trusted_alias_target_mismatch, "/caller/hop", "/private/var"}}} =
             SafeOutput.__test_write__(
               output_path,
               "bytes\n",
               caller_hop_alias_control()
             )
  end

  test "rejects directories and device targets before creating temp output" do
    root = tmp_root("unsupported_targets")
    directory_target = Path.join(root, "directory.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(directory_target)

    assert {:error, {:unsupported_target, ^directory_target, :directory}} =
             SafeOutput.write(directory_target, "bytes\n")

    assert_no_temp_residue!(root)

    case File.lstat("/dev/null") do
      {:ok, %File.Stat{type: type}} when type != :regular ->
        assert {:error, {:unsupported_target, "/dev/null", ^type}} =
                 SafeOutput.write("/dev/null", "bytes\n")

      _other ->
        :ok
    end
  end

  test "rejects parent paths it cannot create or traverse" do
    root = tmp_root("bad_parent")
    file_parent = Path.join(root, "not_a_directory")
    file_parent_output = Path.join(file_parent, "artifact.json")
    denied_parent = Path.join(root, "denied")
    denied_output = Path.join(denied_parent, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(file_parent, "not a directory\n")

    assert {:error, {:unsupported_ancestor, ^file_parent, :regular}} =
             SafeOutput.write(file_parent_output, "bytes\n")

    assert {:error, {:parent_create_failed, ^denied_parent, :eacces}} =
             SafeOutput.__test_write__(denied_output, "bytes\n", %{
               mkdir_p: fn _parent -> {:error, :eacces} end
             })

    refute File.exists?(denied_parent)
    assert_no_temp_residue!(root)
  end

  test "rejects stale temp collision without deleting unowned temp output" do
    root = tmp_root("stale_temp_collision")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    {:ok, temporary_path} = SafeOutput.__test_temporary_path__(output_path)
    File.write!(temporary_path, "unowned temp\n")

    assert {:error, {:temporary_path_exists, ^temporary_path}} =
             SafeOutput.write(output_path, "fresh\n")

    refute File.exists?(output_path)
    assert File.read!(temporary_path) == "unowned temp\n"
  end

  test "maps exclusive-open eexist race to typed temp collision without cleanup" do
    root = tmp_root("open_race_collision")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(output_path, "original\n")
    {:ok, temporary_path} = SafeOutput.__test_temporary_path__(output_path)

    control = %{
      open: fn ^temporary_path, _modes -> {:error, :eexist} end,
      rm: fn _path -> flunk("safe output attempted to clean an unowned temp path") end
    }

    assert {:error, {:temporary_path_exists, ^temporary_path}} =
             SafeOutput.__test_write__(output_path, "replacement\n", control)

    assert File.read!(output_path) == "original\n"
    refute File.exists?(temporary_path)
  end

  test "forced open failure leaves destination intact and does not delete temp output" do
    root = tmp_root("open_failure_without_ownership")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)

    control = %{
      open: fn _temporary_path, _modes -> {:error, :eacces} end,
      rm: fn _temporary_path -> flunk("safe output attempted to delete an unowned temp path") end
    }

    assert {:error, {:write_failed, _temporary_path, :eacces}} =
             SafeOutput.__test_write__(output_path, "replacement\n", control)

    refute File.exists?(output_path)
    assert_no_temp_residue!(root)
  end

  test "forced write failure leaves destination intact and removes owned temp output" do
    root = tmp_root("write_failure")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(output_path, "original\n")

    control = %{
      binwrite: fn io_device, _bytes ->
        :ok = IO.binwrite(io_device, "partial temp\n")
        {:error, :forced_write_failure}
      end
    }

    assert {:error, {:write_failed, _temporary_path, :forced_write_failure}} =
             SafeOutput.__test_write__(output_path, "replacement\n", control)

    assert File.read!(output_path) == "original\n"
    assert_no_temp_residue!(root)
  end

  test "forced rename failure leaves destination intact and removes owned temp output" do
    root = tmp_root("rename_failure")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(output_path, "original\n")

    control = %{rename: fn _temporary_path, _path -> {:error, :forced_rename_failure} end}

    assert {:error, {:rename_failed, _temporary_path, ^output_path, :forced_rename_failure}} =
             SafeOutput.__test_write__(output_path, "replacement\n", control)

    assert File.read!(output_path) == "original\n"
    assert_no_temp_residue!(root)
  end

  test "cleanup failure is typed and may leave owned temp residue" do
    root = tmp_root("cleanup_failure")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(output_path, "original\n")

    control = %{
      rename: fn _temporary_path, _path -> {:error, :forced_rename_failure} end,
      rm: fn _temporary_path -> {:error, :forced_cleanup_failure} end
    }

    assert {:error,
            {:temporary_cleanup_failed, temporary_path, :forced_cleanup_failure, original_reason}} =
             SafeOutput.__test_write__(output_path, "replacement\n", control)

    assert {:rename_failed, ^temporary_path, ^output_path, :forced_rename_failure} =
             original_reason

    assert File.read!(output_path) == "original\n"
    assert File.exists?(temporary_path)
  end

  test "target recheck rejects a concurrent symlink target swap before rename" do
    root = tmp_root("target_recheck_symlink")
    output_path = Path.join(root, "artifact.json")
    real_path = Path.join(root, "real.json")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(root)
    File.write!(real_path, "real\n")

    control = %{
      after_temporary_write: fn ^output_path, _temporary_path ->
        File.ln_s!(real_path, output_path)
        :ok
      end
    }

    assert {:error, {:unsafe_symlink, :target, ^output_path}} =
             SafeOutput.__test_write__(output_path, "replacement\n", control)

    assert File.read!(real_path) == "real\n"
    assert_no_temp_residue!(root)
  end

  test "test control rejects non-map, unknown keys, and callback arity mismatches" do
    root = tmp_root("invalid_test_control")
    output_path = Path.join(root, "artifact.json")

    on_exit(fn -> File.rm_rf(root) end)

    assert {:error, {:invalid_test_control, :not_map}} =
             SafeOutput.__test_write__(output_path, "bytes\n", [])

    assert {:error, {:invalid_test_control, {:unknown_keys, [:bad]}}} =
             SafeOutput.__test_write__(output_path, "bytes\n", %{bad: fn -> :ok end})

    assert {:error, {:invalid_test_control, :rename, {:expected_fun_arity, 2}}} =
             SafeOutput.__test_write__(output_path, "bytes\n", %{rename: fn _path -> :ok end})

    assert {:error, {:invalid_test_control, :read_link, {:expected_fun_arity, 1}}} =
             SafeOutput.__test_write__(output_path, "bytes\n", %{
               read_link: fn _path, _extra -> :ok end
             })

    assert {:error, {:invalid_test_control, :stat, {:expected_fun_arity, 1}}} =
             SafeOutput.__test_write__(output_path, "bytes\n", %{
               stat: fn _path, _extra -> :ok end
             })

    refute File.exists?(root)
  end

  defp tmp_root(name) do
    Path.join(
      System.tmp_dir!(),
      "orbital_dynamics_safe_output_#{name}_#{System.unique_integer([:positive])}"
    )
  end

  defp fake_var_alias_control(overrides) do
    lstat_results =
      %{
        "/" => {:ok, directory_stat()},
        "/var" => {:ok, symlink_stat()},
        "/private" => {:ok, directory_stat()},
        "/private/var" => {:ok, directory_stat()},
        "/var/folders" => {:ok, directory_stat()},
        "/var/folders/test" => {:ok, directory_stat()}
      }
      |> Map.merge(Map.get(overrides, :lstat_results, %{}))

    stat_results =
      %{
        "/" => {:ok, directory_stat()},
        "/private" => {:ok, directory_stat()},
        "/private/var" => {:ok, directory_stat()}
      }
      |> Map.merge(Map.get(overrides, :stat_results, %{}))

    read_link_results =
      %{"/var" => {:ok, "private/var"}}
      |> Map.merge(Map.get(overrides, :read_link_results, %{}))

    %{
      lstat: fn path -> Map.get(lstat_results, path, {:error, :enoent}) end,
      read_link: fn path -> Map.get(read_link_results, path, {:error, :einval}) end,
      stat: fn path -> Map.get(stat_results, path, {:error, :enoent}) end
    }
  end

  defp caller_hop_alias_control do
    base_control =
      fake_var_alias_control(%{
        read_link_results: %{
          "/var" => {:ok, "/caller/hop"},
          "/caller/hop" => {:ok, "/private/var"}
        },
        lstat_results: %{
          "/caller" => {:ok, directory_stat(uid: 501, mode: 0o777)},
          "/caller/hop" => {:ok, symlink_stat(uid: 501, mode: 0o777)}
        },
        stat_results: %{
          "/caller" => {:ok, directory_stat(uid: 501, mode: 0o777)}
        }
      })

    %{
      base_control
      | lstat: fn
          "/caller" -> flunk("safe output inspected caller-controlled alias parent")
          "/caller/hop" -> flunk("safe output lstat followed an intermediate alias hop")
          path -> base_control.lstat.(path)
        end,
        read_link: fn
          "/caller/hop" -> flunk("safe output readlink followed an intermediate alias hop")
          path -> base_control.read_link.(path)
        end,
        stat: fn
          "/caller" -> flunk("safe output stat inspected caller-controlled alias parent")
          "/caller/hop" -> flunk("safe output stat followed an intermediate alias hop")
          path -> base_control.stat.(path)
        end
    }
  end

  defp directory_stat(attrs \\ []) do
    struct(File.Stat, Keyword.merge([type: :directory, uid: 0, mode: 0o755], attrs))
  end

  defp symlink_stat(attrs \\ []) do
    struct(File.Stat, Keyword.merge([type: :symlink, uid: 0, mode: 0o755], attrs))
  end

  defp assert_no_temp_residue!(directory) do
    assert Path.wildcard(Path.join(directory, ".orbital_dynamics-safe-output-*.tmp")) == []
  end
end
