_go_test_output_dir="./"
_go_test_filename_prefix=""
_go_test_entrypoint_function="TestWithCoverage"
_go_test_coverage_dir="$_go_test_output_dir/cover/"
_go_test_source_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
_go_test_runner=""

go-test:build() {
    go-test:wipe-coverage

    printf "[build] building test go binary... "

    mkdir -p $_go_test_coverage_dir

    if build_out=$(:go-test:build "${@}" 2>&1 | tee /dev/stderr); then
        printf "ok.\n"
    else
        printf "fail.\n\n%s\n" "$build_out"
        return 1
    fi
}

go-test:set-output-dir() {
    _go_test_output_dir="$1"

    _go_test_coverage_dir="$_go_test_output_dir/.cover/"
}

go-test:set-runner() {
    local runner="$1"

    _go_test_runner="$runner"
}

go-test:run() {
    local target="$_go_test_coverage_dir/$_go_test_filename_prefix$RANDOM"

    $_go_test_runner "$1" \
        -test.run="$_go_test_entrypoint_function" -test.coverprofile="$target" \
        -- "${@:2}" \
            | sed -ur '/^(PASS|FAIL)$/,$d' \
            | sed -ur '/^--- (PASS|FAIL):/d'
}

go-test:set-prefix() {
    _go_test_filename_prefix="$1"
}

go-test:set-entrypoint-function() {
    _go_test_entrypoint_function="$1"
}

go-test:merge-coverage() {
    gocovmerge $_go_test_coverage_dir/* > $_go_test_output_dir/coverage
}

go-test:wipe-coverage() {
    rm -rf $_go_test_coverage_dir $_go_test_output_dir/coverage
}

:go-test:build() {
    (
        ln -s "$_go_test_source_dir/integration_test.go" .
        trap "unlink integration_test.go" EXIT

        go test -cover -x -c -tags integration -o "${@}" 2>&1 \
            | sed -nr '/^#/,$p' \
            | sed -r 's@.*/_obj_test/@@'
    )
}

if ! which gocovmerge &>/dev/null; then
    echo "[warning] gocovmerge not found, merged coverage will be not generated" >&2

    go-test:make-coverage() {
        :
    }
fi

