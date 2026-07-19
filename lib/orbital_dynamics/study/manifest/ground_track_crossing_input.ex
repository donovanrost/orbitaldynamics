defmodule OrbitalDynamics.Study.Manifest.GroundTrackCrossingInput do
  @moduledoc false

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    TabularEarthOrientationProvider
  }

  alias OrbitalDynamics.Study.Manifest.InputField

  def parse(source) do
    source
    |> Map.get("ground_track_crossings", [])
    |> case do
      requests when is_list(requests) ->
        requests
        |> Enum.reduce_while({:ok, []}, fn request, {:ok, requests} ->
          case crossing(request) do
            {:ok, request} -> {:cont, {:ok, requests ++ [request]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _requests ->
        {:error, {:invalid_field, "ground_track_crossings"}}
    end
  end

  defp crossing(%{"crossing" => "latitude"} = spec) do
    with {:ok, latitude_deg} <- InputField.required_number(spec, "latitude_deg"),
         {:ok, frame} <-
           InputField.optional_atom(spec, "frame", :inertial, ["inertial", "body_fixed"]),
         {:ok, rotation_opts} <- rotation_opts(spec),
         {:ok, id} <- InputField.optional_identifier(spec, "id") do
      request =
        %{
          crossing: :latitude,
          latitude_deg: latitude_deg * 1.0,
          frame: frame,
          id: id
        }
        |> Map.merge(rotation_opts)

      {:ok, request |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()}
    end
  end

  defp crossing(%{"crossing" => "longitude"} = spec) do
    with {:ok, longitude_deg} <- InputField.required_number(spec, "longitude_deg"),
         {:ok, frame} <-
           InputField.optional_atom(spec, "frame", :inertial, ["inertial", "body_fixed"]),
         {:ok, rotation_opts} <- rotation_opts(spec),
         {:ok, id} <- InputField.optional_identifier(spec, "id") do
      request =
        %{
          crossing: :longitude,
          longitude_deg: longitude_deg * 1.0,
          frame: frame,
          id: id
        }
        |> Map.merge(rotation_opts)

      {:ok, request |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()}
    end
  end

  defp crossing(%{"crossing" => _crossing}),
    do: {:error, {:invalid_field, "ground_track_crossings.crossing"}}

  defp crossing(_spec), do: {:error, {:invalid_field, "ground_track_crossings"}}

  defp rotation_opts(spec) do
    with {:ok, rotation_rate_rad_s} <-
           InputField.optional_number(spec, "rotation_rate_rad_s"),
         {:ok, rotation_epoch_s} <- InputField.optional_number(spec, "rotation_epoch_s"),
         {:ok, rotation_angle_offset_rad} <-
           InputField.optional_number(spec, "rotation_angle_offset_rad"),
         {:ok, earth_rotation_provider} <- earth_rotation_provider(spec) do
      {:ok,
       %{}
       |> maybe_put(:rotation_rate_rad_s, rotation_rate_rad_s)
       |> maybe_put(:rotation_epoch_s, rotation_epoch_s)
       |> maybe_put(:rotation_angle_offset_rad, rotation_angle_offset_rad)
       |> maybe_put(:earth_rotation_provider, earth_rotation_provider)}
    end
  end

  defp earth_rotation_provider(spec) do
    case Map.fetch(spec, "earth_rotation_provider") do
      {:ok, "constant_earth_rotation"} ->
        {:ok, ConstantEarthRotationProvider}

      {:ok, "tabular_earth_orientation"} ->
        {:error, {:missing_field, "ground_track_crossings.earth_rotation_provider.samples"}}

      {:ok, %{"provider" => "constant_earth_rotation"}} ->
        {:ok, ConstantEarthRotationProvider}

      {:ok, %{"provider" => "tabular_earth_orientation"} = provider_spec} ->
        tabular_earth_rotation_provider(provider_spec)

      {:ok, _provider} ->
        {:error, {:invalid_field, "ground_track_crossings.earth_rotation_provider"}}

      :error ->
        {:ok, nil}
    end
  end

  defp tabular_earth_rotation_provider(provider_spec) do
    with {:ok, samples} <- earth_rotation_samples(provider_spec),
         {:ok, source} <- InputField.optional_string(provider_spec, "source"),
         {:ok, provider_id} <- InputField.optional_string(provider_spec, "provider_id") do
      opts =
        [samples: samples]
        |> maybe_keyword_put(:source, source)
        |> maybe_keyword_put(:provider_id, provider_id)

      {:ok, {TabularEarthOrientationProvider, opts}}
    end
  end

  defp earth_rotation_samples(provider_spec) do
    case Map.fetch(provider_spec, "samples") do
      {:ok, samples} when is_list(samples) and samples != [] ->
        samples
        |> Enum.reduce_while({:ok, []}, fn sample, {:ok, acc} ->
          case earth_rotation_sample(sample) do
            {:ok, sample} -> {:cont, {:ok, acc ++ [sample]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:ok, _samples} ->
        {:error, {:invalid_field, "ground_track_crossings.earth_rotation_provider.samples"}}

      :error ->
        {:error, {:missing_field, "ground_track_crossings.earth_rotation_provider.samples"}}
    end
  end

  defp earth_rotation_sample(%{} = sample) do
    with {:ok, seconds_since_j2000} <-
           earth_rotation_sample_number(
             sample,
             [
               "seconds_since_j2000",
               "epoch_s"
             ],
             "seconds_since_j2000"
           ),
         {:ok, angle_rad} <-
           earth_rotation_sample_number(
             sample,
             [
               "earth_rotation_angle_rad",
               "rotation_angle_rad"
             ],
             "earth_rotation_angle_rad"
           ),
         {:ok, rate_rad_s} <-
           optional_earth_rotation_sample_number(sample, [
             "earth_rotation_rate_rad_s",
             "rotation_rate_rad_s"
           ]) do
      {:ok,
       %{
         seconds_since_j2000: seconds_since_j2000 * 1.0,
         earth_rotation_angle_rad: angle_rad * 1.0
       }
       |> maybe_put(:earth_rotation_rate_rad_s, rate_rad_s)}
    end
  end

  defp earth_rotation_sample(_sample),
    do: {:error, {:invalid_field, "ground_track_crossings.earth_rotation_provider.samples"}}

  defp earth_rotation_sample_number(sample, keys, field) do
    keys
    |> Enum.find_value(fn key ->
      case Map.get(sample, key) do
        value when is_number(value) -> {:ok, value}
        _value -> nil
      end
    end)
    |> case do
      {:ok, value} ->
        {:ok, value}

      nil ->
        {:error,
         {:missing_field, "ground_track_crossings.earth_rotation_provider.samples.#{field}"}}
    end
  end

  defp optional_earth_rotation_sample_number(sample, keys) do
    keys
    |> Enum.find_value(fn key ->
      case Map.get(sample, key) do
        value when is_number(value) -> {:ok, value * 1.0}
        _value -> nil
      end
    end)
    |> case do
      {:ok, value} -> {:ok, value}
      nil -> {:ok, nil}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_keyword_put(keyword, _key, nil), do: keyword
  defp maybe_keyword_put(keyword, key, value), do: Keyword.put(keyword, key, value)
end
