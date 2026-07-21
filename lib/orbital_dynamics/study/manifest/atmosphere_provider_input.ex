defmodule OrbitalDynamics.Study.Manifest.AtmosphereProviderInput do
  @moduledoc false

  alias OrbitalDynamics.Environment.ExponentialAtmosphereProvider

  @provider_field "propagator_opts.atmosphere_provider"
  @supported_keys [
    "provider",
    "reference_altitude_km",
    "reference_density_kg_m3",
    "scale_height_km"
  ]

  def parse(nil), do: {:ok, nil}
  def parse("exponential_reference"), do: {:ok, ExponentialAtmosphereProvider}

  def parse(%{} = spec) do
    with :ok <- validate_keys(spec),
         :ok <- validate_provider(spec),
         {:ok, reference_altitude_km} <- optional_number(spec, "reference_altitude_km"),
         {:ok, reference_density_kg_m3} <-
           optional_non_negative_number(spec, "reference_density_kg_m3"),
         {:ok, scale_height_km} <- optional_positive_number(spec, "scale_height_km") do
      opts =
        []
        |> maybe_put(:reference_altitude_km, reference_altitude_km)
        |> maybe_put(:reference_density_kg_m3, reference_density_kg_m3)
        |> maybe_put(:scale_height_km, scale_height_km)

      if opts == [] do
        {:ok, ExponentialAtmosphereProvider}
      else
        {:ok, {ExponentialAtmosphereProvider, opts}}
      end
    end
  end

  def parse(_spec), do: {:error, {:invalid_field, @provider_field}}

  defp validate_keys(spec) do
    case spec |> Map.keys() |> Enum.sort() |> Enum.find(&(&1 not in @supported_keys)) do
      nil -> :ok
      key -> {:error, {:unsupported_option, @provider_field, key}}
    end
  end

  defp validate_provider(%{"provider" => "exponential_reference"}), do: :ok

  defp validate_provider(%{"provider" => _provider}),
    do: {:error, {:invalid_field, "#{@provider_field}.provider"}}

  defp validate_provider(_spec), do: {:error, {:missing_field, "#{@provider_field}.provider"}}

  defp optional_number(spec, key) do
    case Map.fetch(spec, key) do
      {:ok, value} when is_number(value) -> {:ok, value * 1.0}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, "#{@provider_field}.#{key}"}}
      :error -> {:ok, nil}
    end
  end

  defp optional_non_negative_number(spec, key) do
    with {:ok, value} <- optional_number(spec, key) do
      if is_nil(value) or value >= 0.0,
        do: {:ok, value},
        else: {:error, {:invalid_field, "#{@provider_field}.#{key}"}}
    end
  end

  defp optional_positive_number(spec, key) do
    with {:ok, value} <- optional_number(spec, key) do
      if is_nil(value) or value > 0.0,
        do: {:ok, value},
        else: {:error, {:invalid_field, "#{@provider_field}.#{key}"}}
    end
  end

  defp maybe_put(keyword, _key, nil), do: keyword
  defp maybe_put(keyword, key, value), do: Keyword.put(keyword, key, value)
end
