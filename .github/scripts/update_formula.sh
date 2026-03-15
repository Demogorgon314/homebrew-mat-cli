#!/usr/bin/env bash

set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-Demogorgon314/mat-cli}"
FORMULA_PATH="${FORMULA_PATH:-Formula/mat-cli.rb}"

release_json="$(curl -fsSL -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${SOURCE_REPO}/releases/latest")"

tag_name="$(jq -r '.tag_name' <<<"${release_json}")"
if [[ -z "${tag_name}" || "${tag_name}" == "null" ]]; then
  echo "Unable to determine latest release tag for ${SOURCE_REPO}" >&2
  exit 1
fi

asset_json="$(jq -c '.assets[] | select(.name | test("^mat-cli-v?.*\\.zip$"))' <<<"${release_json}" | head -n 1)"
if [[ -z "${asset_json}" ]]; then
  echo "Unable to find mat-cli zip asset in latest release for ${SOURCE_REPO}" >&2
  exit 1
fi

asset_url="$(jq -r '.browser_download_url' <<<"${asset_json}")"
sha256="$(jq -r '.digest // "" | sub("^sha256:"; "")' <<<"${asset_json}")"
version="${tag_name#v}"
current_version=""
current_revision=""

if [[ -f "${FORMULA_PATH}" ]]; then
  current_version="$(sed -n 's/^  version "\(.*\)"/\1/p' "${FORMULA_PATH}" | head -n 1)"
  current_revision="$(sed -n 's/^  revision \(.*\)$/\1/p' "${FORMULA_PATH}" | head -n 1)"
fi

if [[ -z "${sha256}" ]]; then
  tmp_file="$(mktemp)"
  trap 'rm -f "${tmp_file}"' EXIT
  curl -fsSL -o "${tmp_file}" "${asset_url}"
  sha256="$(shasum -a 256 "${tmp_file}" | awk '{print $1}')"
fi

cat > "${FORMULA_PATH}" <<EOF
class MatCli < Formula
  desc "Headless Java heap analyzer for Eclipse Memory Analyzer"
  homepage "https://github.com/${SOURCE_REPO}"
  version "${version}"
EOF

if [[ "${current_version}" == "${version}" && -n "${current_revision}" ]]; then
  cat >> "${FORMULA_PATH}" <<EOF
  revision ${current_revision}
EOF
fi

cat >> "${FORMULA_PATH}" <<EOF
  url "${asset_url}"
  sha256 "${sha256}"
  license "EPL-2.0"

  livecheck do
    url :stable
    regex(/^mat-cli-v?(\\d+(?:\\.\\d+)+)\\.zip$/i)
  end

  depends_on "openjdk@17"

  def install
    libexec.install Dir["*"]
    (bin/"mat-cli").write_env_script libexec/"mat-cli",
                                     Language::Java.overridable_java_home_env("17")
  end

  test do
    assert_match "mat-cli", shell_output("#{bin}/mat-cli --help")
  end
end
EOF

echo "Updated ${FORMULA_PATH} to ${version}"
