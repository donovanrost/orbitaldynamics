defmodule OrbitalDynamics.CampaignEnvironmentValidationReuseTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider, as: Provider
  @first 820_497_600.0
  @digest {Provider, :dataset_semantic_sha256, 1}

  # Trace only this worker, then drain through a delivery barrier. No cache-key
  # inspection or production counters: observe actual canonical hash work.
  defp hash_work(fun) do
    Code.ensure_loaded!(Provider)
    :erlang.trace_pattern(@digest, true, [:local])
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        receive do
          :run ->
            value = fun.()
            send(parent, {:value, self(), value})

            receive do
              :stop -> :ok
            end
        end
      end)

    try do
      :erlang.trace(pid, true, [:call, {:tracer, self()}])
      send(pid, :run)

      value =
        receive do
          {:value, ^pid, value} ->
            value

          {:DOWN, ^monitor, :process, ^pid, why} ->
            flunk("validation worker failed: #{inspect(why)}")
        after
          10_000 -> flunk("validation worker timed out")
        end

      barrier = :erlang.trace_delivered(pid)

      receive do
        {:trace_delivered, ^pid, ^barrier} -> :ok
      after
        10_000 -> flunk("trace delivery timed out")
      end

      {value, calls(pid, 0)}
    after
      :erlang.trace_pattern(@digest, false, [:local])
      send(pid, :stop)
      Process.demonitor(monitor, [:flush])
      if Process.alive?(pid), do: Process.exit(pid, :kill)
    end
  end

  defp calls(pid, n) do
    receive do
      {:trace, ^pid, :call, {Provider, :dataset_semantic_sha256, [_]}} -> calls(pid, n + 1)
    after
      0 -> n
    end
  end

  test "repeated products, capability and provenance hash an unchanged dataset once" do
    {provenance, count} =
      hash_work(fn ->
        {:ok, d} = Provider.load(Provider.checked_in_options())
        expected = Provider.provenance(d)
        copy = d |> :erlang.term_to_binary() |> :erlang.binary_to_term()
        assert copy === d

        for n <- 0..19 do
          assert Provider.provenance(copy) === expected
          assert {:ok, cap} = Provider.configured_capability(dataset: copy)
          assert cap["provenance"] === expected

          for kind <- [:sun_direction, :earth_rotation] do
            assert {:ok, p} = Provider.fetch(kind, dataset: copy, seconds_since_j2000: @first + n)
            assert p["provenance"] === expected
            assert p["dataset_semantic_sha256"] == expected["dataset_semantic_sha256"]
          end
        end

        expected
      end)

    assert count == 1

    assert provenance["dataset_semantic_sha256"] ==
             "afb0c7252b0b2d2c7e987651e639e02b76bc9ac1ff19d0927b3bf3e6a9ebb5db"
  end

  test "numeric equality is insufficient and failed admissions do not replace the valid entry" do
    {_, count} =
      hash_work(fn ->
        {:ok, d} = Provider.load(Provider.checked_in_options())
        numeric_copy = %{d | sample_interval_s: trunc(d.sample_interval_s)}
        assert numeric_copy == d and not (numeric_copy === d)

        assert {:error, {:invalid_campaign_environment_dataset, :semantic_digest_mismatch, _, _}} =
                 Provider.provenance(numeric_copy)

        bad = %{
          d
          | content_verification:
              Map.put(d.content_verification, "actual_sha256", String.duplicate("0", 64))
        }

        assert {:error, {:invalid_campaign_environment_dataset, :file_verification}} =
                 Provider.provenance(bad)

        assert %{} = Provider.provenance(d)
      end)

    assert count == 2
  end

  test "cache retains one complete value and does not return another file's provenance" do
    {_, count} =
      hash_work(fn ->
        {:ok, d} = Provider.load(Provider.checked_in_options())
        a = Provider.provenance(d)

        other = %{
          d
          | content_verification:
              Map.put(d.content_verification, "path", "same-verified-bytes-another-path")
        }

        b = Provider.provenance(other)
        assert b["dataset_semantic_sha256"] == a["dataset_semantic_sha256"]
        assert b["file_content_verification"]["path"] == "same-verified-bytes-another-path"
        refute a === b
        assert Provider.provenance(d) === a
      end)

    assert count == 3
  end

  test "each process independently validates and query gates remain active after a cache hit" do
    for _ <- 1..2 do
      {_, count} =
        hash_work(fn ->
          {:ok, d} = Provider.load(Provider.checked_in_options())

          assert {:error, {:outside_coverage, :campaign_environment}} =
                   Provider.fetch(:sun_direction, dataset: d, seconds_since_j2000: @first - 1)

          assert {:error, {:campaign_environment_request_mismatch, :body, _, _}} =
                   Provider.fetch(:sun_direction,
                     dataset: d,
                     seconds_since_j2000: @first,
                     body: :mars
                   )

          assert {:error, {:campaign_environment_request_mismatch, :time_scale, _, _}} =
                   Provider.fetch(:earth_rotation,
                     dataset: d,
                     seconds_since_j2000: @first,
                     time_scale: :tdb
                   )

          assert {:error, {:campaign_environment_request_mismatch, :interpolation, _, _}} =
                   Provider.fetch(:sun_direction,
                     dataset: d,
                     seconds_since_j2000: @first,
                     interpolation: :cubic
                   )

          assert {:error, _} =
                   Provider.fetch(:sun_direction,
                     dataset: d,
                     dataset: d,
                     seconds_since_j2000: @first
                   )

          assert {:ok, _} =
                   Provider.fetch(:sun_direction, dataset: d, seconds_since_j2000: @first)
        end)

      assert count == 1
    end
  end

  test "a new code version independently admits an already cached dataset" do
    path =
      Path.expand(
        "../../lib/orbital_dynamics/environment/campaign_environment_provider.ex",
        __DIR__
      )

    source = File.read!(path)
    anchor = "  defp canonical_term(value), do: value"
    assert String.contains?(source, anchor)

    upgraded =
      String.replace(
        source,
        anchor,
        anchor <> "\n  def validation_reuse_test_probe, do: :new_code"
      )

    options = Code.compiler_options(ignore_module_conflict: true)

    try do
      {_, count} =
        hash_work(fn ->
          {:ok, d} = Provider.load(Provider.checked_in_options())
          before = Provider.provenance(d)
          Code.compile_string(upgraded, path)
          :erlang.trace_pattern(@digest, true, [:local])
          assert Provider.provenance(d) === before

          assert {:ok, _} =
                   Provider.fetch(:sun_direction, dataset: d, seconds_since_j2000: @first)
        end)

      assert count == 2
    after
      Code.compile_string(source, path)
      Code.compiler_options(options)
    end
  end
end
