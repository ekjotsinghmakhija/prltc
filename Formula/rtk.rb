# typed: false
# frozen_string_literal: true

# Homebrew formula for prltc - Rust Token Killer
# To install: brew tap pszymkowiak/tap && brew install prltc
class Rtk < Formula
  desc "High-performance CLI proxy to minimize LLM token consumption"
  homepage "https://github.com/pszymkowiak/prltc"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_intel do
      url "https://github.com/pszymkowiak/prltc/releases/download/v#{version}/prltc-x86_64-apple-darwin.tar.gz"
      sha256 "PLACEHOLDER_SHA256_INTEL"
    end

    on_arm do
      url "https://github.com/pszymkowiak/prltc/releases/download/v#{version}/prltc-aarch64-apple-darwin.tar.gz"
      sha256 "PLACEHOLDER_SHA256_ARM"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/pszymkowiak/prltc/releases/download/v#{version}/prltc-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "PLACEHOLDER_SHA256_LINUX_INTEL"
    end

    on_arm do
      url "https://github.com/pszymkowiak/prltc/releases/download/v#{version}/prltc-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "PLACEHOLDER_SHA256_LINUX_ARM"
    end
  end

  def install
    bin.install "prltc"
  end

  test do
    assert_match "prltc #{version}", shell_output("#{bin}/prltc --version")
  end
end
