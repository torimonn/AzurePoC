#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_ROOT="$(cd "${SOLUTION_DIR}/.." && pwd)"
DIST_DIR="${TERRAFORM_ROOT}/dist"
PACKAGE_NAME="ocr-demo-offline"
PACKAGE_DIR="${DIST_DIR}/${PACKAGE_NAME}"
ARCHIVE_PATH="${DIST_DIR}/${PACKAGE_NAME}.tar.gz"

terraform -chdir="${SOLUTION_DIR}" fmt -check -recursive
terraform -chdir="${SOLUTION_DIR}" init -backend=false
terraform -chdir="${SOLUTION_DIR}" validate
terraform -chdir="${SOLUTION_DIR}" providers lock -platform=linux_amd64

rm -rf "${PACKAGE_DIR}" "${ARCHIVE_PATH}"
mkdir -p "${PACKAGE_DIR}/solution/.terraform" "${PACKAGE_DIR}/provider-mirror"

terraform -chdir="${SOLUTION_DIR}" providers mirror \
  -platform=linux_amd64 \
  "${PACKAGE_DIR}/provider-mirror"

for file in \
  "${SOLUTION_DIR}"/*.tf \
  "${SOLUTION_DIR}"/*.md \
  "${SOLUTION_DIR}"/*.example \
  "${SOLUTION_DIR}"/.terraform.lock.hcl; do
  if [[ -f "${file}" ]]; then
    cp "${file}" "${PACKAGE_DIR}/solution/"
  fi
done

cp -R "${SOLUTION_DIR}/docs" "${PACKAGE_DIR}/solution/"
cp -R "${SOLUTION_DIR}/scripts" "${PACKAGE_DIR}/solution/"
cp -R "${SOLUTION_DIR}/.terraform/modules" "${PACKAGE_DIR}/solution/.terraform/"

cat > "${PACKAGE_DIR}/terraform.rc.example" <<'EOF'
provider_installation {
  filesystem_mirror {
    path    = "/opt/terraform/provider-mirror"
    include = ["registry.terraform.io/*/*"]
  }
}
EOF

cat > "${PACKAGE_DIR}/MANIFEST.md" <<'EOF'
# AI業務アシスト閉域配布パッケージ

このパッケージには、固定版AVMの取得済みmodule treeとlinux_amd64用Provider mirrorを含みます。

実際のterraform.tfvars、backend.hcl、state、plan、Secretは含みません。

## SHA-256

```text
EOF

(
  cd "${PACKAGE_DIR}"
  find . -type f ! -name MANIFEST.md -print0 | sort -z | xargs -0 sha256sum
) >> "${PACKAGE_DIR}/MANIFEST.md"

cat >> "${PACKAGE_DIR}/MANIFEST.md" <<'EOF'
```
EOF

tar -C "${DIST_DIR}" -czf "${ARCHIVE_PATH}" "${PACKAGE_NAME}"

printf 'Created: %s\n' "${ARCHIVE_PATH}"
