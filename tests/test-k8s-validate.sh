#!/usr/bin/env bash
# Tests of scripts/k8s-validate.sh. Run it with `mise exec -- tests/test-k8s-validate.sh`. It runs
# the script with kustomize, helm, yq, kubeconform and trivy.
#
# The cases: a test chart renders its one dependency with the values template of its folder; the
# render writes each object to its own file; kubeconform accepts a CustomResourceDefinition; and a
# trivy ignore file and a kube-linter ignore file admit only the findings that they name, on the
# objects that they name. The charts and the Kustomize root come from tests/fixtures/, and the test
# writes the other files, so it needs no file of a consumer.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validate="$root/scripts/k8s-validate.sh"
fixtures="$root/tests/fixtures"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
ignore="$work/trivyignore.yaml"
kl_ignore="$work/kubelinterignore.yaml"
failures=0
cases=0

pass() {
  cases=$((cases + 1))
  echo "ok   $1"
}

fail() {
  cases=$((cases + 1))
  failures=$((failures + 1))
  echo "FAIL $1"
  if [ -f "$work/log" ]; then
    sed 's/^/     /' "$work/log" | tail -20
  fi
}

# run WANT NAME COMMAND...: run COMMAND and compare its exit code with WANT.
run() {
  local want="$1" name="$2" got=0
  shift 2
  "$@" >"$work/log" 2>&1 || got=$?
  if [ "$got" -eq "$want" ]; then
    pass "$name"
  else
    fail "$name: exit $got, want $want"
  fi
}

# says NAME TEXT: the output of the last run has the line TEXT.
says() {
  if grep -qF -- "$2" "$work/log"; then
    pass "$1"
  else
    fail "$1: the output has no line $2"
  fi
}

# expect NAME FILE EXPRESSION WANT: the yq expression EXPRESSION on FILE gives the text WANT.
expect() {
  local got
  got="$(yq "$3" "$2" 2>&1)" || true
  if [ "$got" = "$4" ]; then
    pass "$1"
  else
    fail "$1: got $got, want $4"
  fi
}

# The test chart of a values template, with the chart tests/fixtures/charts/example as its
# dependency.
template="$work/helm/demo"
mkdir -p "$template/test-chart/templates"
printf 'host: template.example.com\n' >"$template/values.yaml"
printf '{}\n' >"$template/test-chart/values.yaml"
cat >"$template/test-chart/Chart.yaml" <<EOF
apiVersion: v2
name: test-chart
version: 0.1.0
dependencies:
  - name: example
    version: 0.1.0
    repository: file://$fixtures/charts/example
EOF
out="$work/test-chart"
run 0 "a test chart renders" env HELM_CHARTS="$template/test-chart" RENDERED="$out" "$validate" render
expect "a test chart renders its dependency with the values template, as a release of the dependency" \
  "$out/1-helm-example/ConfigMap-example-example.yaml" '.data.url' 'https://template.example.com/'

# A test chart with two dependencies has no one name for the values template.
yq -i '.dependencies += [.dependencies[0] | .alias = "second"]' "$template/test-chart/Chart.yaml"
rm -rf "$template/test-chart/Chart.lock" "$template/test-chart/charts"
run 1 "a test chart with two dependencies stops the render" \
  env HELM_CHARTS="$template/test-chart" RENDERED="$work/two" "$validate" render
says "the render names the rule of a test chart" "a test chart needs one dependency and the values template"

out="$work/kustomize"
run 0 "a Kustomize root renders" env KUSTOMIZE_ROOTS="$fixtures/k8s/tests/example/" RENDERED="$out" \
  "$validate" render
expect "the render writes each object to the file <namespace>/<kind>-<name>.yaml" \
  "$out/1-kustomize-example/example/PersistentVolumeClaim-example.yaml" '.kind + "/" + .metadata.name' \
  'PersistentVolumeClaim/example'
files="$(find "$out" -type f -name '*.yaml' | wc -l)"
objects="$(kustomize build "$fixtures/k8s/tests/example" | yq ea '[.] | length')"
if [ "$files" -eq "$objects" ]; then
  pass "the render writes one file for each object"
else
  fail "the render writes one file for each object: $files files, $objects objects"
fi
# A chart with an object in a namespace of its own.
namespaced="$work/namespaced"
mkdir -p "$namespaced/templates"
printf 'apiVersion: v2\nname: namespaced\nversion: 0.1.0\n' >"$namespaced/Chart.yaml"
printf '{}\n' >"$namespaced/values.yaml"
printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: settings\n  namespace: example-db\n' \
  >"$namespaced/templates/configmap.yaml"
out="$work/namespaced-out"
run 0 "a chart renders" env HELM_CHARTS="$fixtures/charts/example
$namespaced" RENDERED="$out" "$validate" render
expect "the render writes a namespaced object to the folder of its namespace" \
  "$out/2-helm-namespaced/example-db/ConfigMap-settings.yaml" '.metadata.namespace' 'example-db'

# Two objects with one kind, namespace and name would write one file.
twice="$work/twice"
mkdir -p "$twice/templates"
printf 'apiVersion: v2\nname: twice\nversion: 0.1.0\n' >"$twice/Chart.yaml"
printf '{}\n' >"$twice/values.yaml"
for _ in 1 2; do
  printf -- '---\napiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: same\n'
done >"$twice/templates/configmaps.yaml"
run 1 "two objects with one file stop the render" env HELM_CHARTS="$twice" RENDERED="$work/twice-out" "$validate" render
says "the render names the file of the two objects" "more than one object with the file ConfigMap-same.yaml"

# kubeconform finds the schema of a CustomResourceDefinition.
mkdir -p "$work/crd"
cat >"$work/crd/crd.yaml" <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.com
spec:
  group: example.com
  names:
    kind: Widget
    plural: widgets
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
EOF
run 0 "kubeconform accepts a CustomResourceDefinition" env RENDERED="$work/crd" "$validate" kubeconform

# cluster_role FOLDER NAME RESOURCE: write a ClusterRole NAME that can update RESOURCE to the render
# folder FOLDER, as the render step does.
cluster_role() {
  rm -rf "$work/trivy"
  mkdir -p "$work/trivy/$1"
  {
    printf 'apiVersion: rbac.authorization.k8s.io/v1\nkind: ClusterRole\nmetadata:\n  name: %s\n' "$2"
    if [ "$3" = secrets ]; then
      printf 'rules:\n  - apiGroups: [""]\n    resources: [secrets]\n    verbs: [get, update]\n'
    else
      printf 'rules:\n  - apiGroups: [admissionregistration.k8s.io]\n    resources: [%s]\n    verbs: [update]\n' "$3"
    fi
  } >"$work/trivy/$1/ClusterRole-$2.yaml"
}

trivy_step() {
  env RENDERED="$work/trivy" TRIVY_IGNORE_FILE="$ignore" "$validate" trivy
}

# A trivy ignore file in the form of a consumer: each entry names one finding ID on the file of one
# object of one release, with a statement and an expiry date.
cat >"$ignore" <<'EOF2'
misconfigurations:
  - id: KSV-0041
    paths:
      - "*-helm-demo/ClusterRole-demo-controller.yaml"
    statement: The controller of the test writes Secrets in each namespace.
    expired_at: 2999-12-31
  - id: KSV-0114
    paths:
      - "*-helm-demo/ClusterRole-demo-webhook.yaml"
    statement: The webhook of the test writes its CA bundle into its webhook configurations.
    expired_at: 2999-12-31
EOF2

cluster_role 1-helm-demo demo-controller secrets
run 0 "trivy: the accepted KSV-0041 on ClusterRole demo-controller passes" trivy_step
cluster_role 1-helm-demo demo-webhook validatingwebhookconfigurations
run 0 "trivy: the accepted KSV-0114 on ClusterRole demo-webhook passes" trivy_step
cluster_role 1-helm-demo demo-controller validatingwebhookconfigurations
run 1 "trivy: KSV-0114 on ClusterRole demo-controller fails" trivy_step
cluster_role 1-helm-demo demo-view secrets
run 1 "trivy: KSV-0041 on another ClusterRole of the release fails" trivy_step
cluster_role 1-helm-other demo-controller secrets
run 1 "trivy: KSV-0041 on ClusterRole demo-controller of another release fails" trivy_step
cluster_role 1-helm-demo demo-controller secrets
run 1 "trivy: the findings fail with no ignore file" env RENDERED="$work/trivy" "$validate" trivy
run 1 "trivy: an ignore file that does not exist stops the step" \
  env RENDERED="$work/trivy" TRIVY_IGNORE_FILE="$work/no-file.yaml" "$validate" trivy
says "trivy: the step names the ignore file that does not exist" "$work/no-file.yaml does not exist"

# workload FOLDER KIND NAME: write a workload KIND NAME with no probe to the render folder FOLDER.
workload() {
  rm -rf "$work/kube-linter"
  mkdir -p "$work/kube-linter/$1"
  local extra=""
  if [ "$2" = "StatefulSet" ]; then
    extra="serviceName: $3-headless
  updateStrategy:
    type: RollingUpdate"
  else
    extra="strategy:
    type: RollingUpdate"
  fi
  cat >"$work/kube-linter/$1/$2-$3.yaml" <<EOF
apiVersion: apps/v1
kind: $2
metadata:
  name: $3
spec:
  replicas: 1
  $extra
  selector:
    matchLabels:
      app: $3
  template:
    metadata:
      labels:
        app: $3
    spec:
      serviceAccountName: default
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: app:1.0.0
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              memory: 128Mi
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
EOF
  cat >"$work/kube-linter/$1/NetworkPolicy-$3.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $3
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF
}

kl_step() {
  env RENDERED="$work/kube-linter" KUBE_LINTER_IGNORE_FILE="$kl_ignore" "$validate" kube-linter
}

# A kube-linter ignore file in the form of a consumer: each entry names one check on the files of
# the objects that it names, with a statement and an expiry date.
cat >"$kl_ignore" <<'EOF2'
checks:
  - check: no-liveness-probe
    paths:
      - "*-helm-demo/*/Deployment-demo-operator.yaml"
      - "*-helm-demo/Deployment-demo-operator.yaml"
      - "*-helm-demo/StatefulSet-demo.yaml"
    statement: The upstream chart of the test has no value for a liveness probe.
    expired_at: 2999-12-31
EOF2

workload 1-helm-demo Deployment demo-operator
run 0 "kube-linter: the accepted no-liveness-probe on Deployment demo-operator passes" kl_step
workload 1-helm-demo StatefulSet demo
run 0 "kube-linter: the accepted no-liveness-probe on StatefulSet demo passes" kl_step
workload 1-helm-other StatefulSet other-workload
run 1 "kube-linter: no-liveness-probe on StatefulSet other-workload fails" kl_step
workload 1-helm-demo StatefulSet demo
run 1 "kube-linter: the finding fails with no ignore file" env RENDERED="$work/kube-linter" "$validate" kube-linter
run 1 "kube-linter: an ignore file that does not exist stops the step" \
  env RENDERED="$work/kube-linter" KUBE_LINTER_IGNORE_FILE="$work/no-kl-file.yaml" "$validate" kube-linter
says "kube-linter: the step names the ignore file that does not exist" "$work/no-kl-file.yaml does not exist"
sed -i 's/expired_at: 2999-12-31/expired_at: 2000-01-01/' "$kl_ignore"
run 1 "kube-linter: an expired judgment stops the step" kl_step
says "kube-linter: the step names the expired judgment" "judgment for no-liveness-probe expired on 2000-01-01"

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
