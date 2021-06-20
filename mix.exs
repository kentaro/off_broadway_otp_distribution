defmodule OffBroadwayOtpDistribution.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "An OTP distribution connector for Broadway"
  @repo_url "https://github.com/kentaro/off_broadway_otp_distribution"

  def project do
    [
      app: :off_broadway_otp_distribution,
      version: @version,
      elixir: "~> 1.12.0",
      name: "OffBroadwayOtpDistribution",
      description: @description,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway, "~> 0.6.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:cll, "~> 0.1.0"}
    ]
  end

  defp docs do
    [
      main: "OffBroadwayOtpDistribution",
      nest_modules_by_prefix: [OffBroadwayOtpDistribution],
      source_ref: @version,
      source_url: @repo_url,
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    }
  end
end
