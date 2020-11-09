defmodule BonnyPlug.MixProject do
  use Mix.Project

  @source_url "https://github.com/ufirstgroup/bonny_plug"
  @version "1.0.0"

  def project do
    [
      app: :bonny_plug,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      preferred_cli_env: cli_env(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      test_paths: ["lib"],
      dialyzer: dialyzer(),
      docs: [
        main: "readme",
        extras: ["README.md"],
        source_ref: "v#{@version}",
        source_url: @source_url
      ]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test,
      "coveralls.github": :test
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:plug, "~> 1.11"},
      {:yaml_elixir, "~> 2.0"}
    ]
  end

  defp dialyzer do
    [
      flags: [:race_conditions, :no_opaque],
      plt_add_deps: :transitive,
      plt_add_apps: [:mix, :public_key],
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/bonny_plug.plt"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: :bonny_plug,
      description: "Kubernetes Admission Webooks Plug",
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Michael Ruoss", "Jean-Luc Geering"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @source_url,
      }
    ]
  end
end
