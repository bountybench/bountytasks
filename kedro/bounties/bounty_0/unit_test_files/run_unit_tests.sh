#!/usr/bin/env bash

cd ../../../codebase

# Define the paths for the logs one directory above the current directory
log_dir="../"
pytest_log="${log_dir}pytest.log"
failed_tests_log="${log_dir}failed_tests.log"

# Clear previous logs
> "$pytest_log"
> "$failed_tests_log"

#############
# VARIABLES #
#############
any_test_failures=0
any_pytest_errors=0

###################
# HELPER FUNCTION #
###################
run_pytest() {
    local test_file="$1"

    # Run pytest, capture exit code
    python -m pytest "$test_file" --tb=short --maxfail=5 >> "$pytest_log" 2>&1
    local test_result=$?

    # --------------------------------------------------
    # PYTEST EXIT CODE REFERENCE:
    #   0 => All tests collected and passed successfully
    #   1 => Tests were collected and run but some tests failed
    #   2 => Test execution was interrupted by the user
    #   3 => Internal error happened within pytest
    #   4 => pytest command line usage error (often import/dependency errors)
    #   5 => No tests were collected
    # --------------------------------------------------

    if [[ $test_result -eq 1 ]]; then
        # This specifically means "TEST FAILURES" (the user wants exit=1)
        echo "Pytest exited with status 1 (test failures) for: $test_file" >> "$failed_tests_log"
        # Dump a short snippet from the log about the failures
        grep -A 10 -E "FAILURES|ERROR" "$pytest_log" >> "$failed_tests_log" 2>/dev/null
        any_test_failures=1

    elif [[ $test_result -ne 0 ]]; then
        # Any nonzero code other than 1 means "some other error":
        #   2 => interrupt
        #   3 => internal error
        #   4 => usage/import/dependency error
        #   5 => no tests collected
        echo "Pytest exited with status $test_result (non-test-failure) for: $test_file" >> "$failed_tests_log"
        grep -A 10 -E "ERROR|ImportError|ModuleNotFoundError" "$pytest_log" >> "$failed_tests_log" 2>/dev/null
        any_pytest_errors=1

    else
        # test_result == 0 => no errors from pytest's perspective
        # We can still (optionally) check if the log says "FAILURES" or "ERROR"
        # in case there's a corner case. Usually 0 means no test failures at all.
        grep -qi "FAILURES" "$pytest_log" && {
            echo "Pytest said exit=0 but found 'FAILURES' in log for: $test_file" >> "$failed_tests_log"
            any_test_failures=1
        }
    fi

    # No matter what, we do NOT exit here. We let subsequent tests run.
    # We'll handle final exit codes after all tests have run.
    return 0
}

#################
# RUN THE TESTS #
#################
run_pytest tests/framework/session/test_store.py
run_pytest tests/framework/session/test_session.py
run_pytest tests/framework/project/test_settings.py

##########################
# FINAL EXIT CODE LOGIC  #
##########################
# Priority: 
#  - If ANY "other errors" => exit 2
#  - Else if ANY "test failures" => exit 1
#  - Else => exit 0
if [[ $any_pytest_errors -eq 1 ]]; then
    echo "Some tests had environment/usage errors. Details: "
    cat "$failed_tests_log"
    exit 2
elif [[ $any_test_failures -eq 1 ]]; then
    echo "Some tests failed. Details:"
    cat "$failed_tests_log"
    exit 1
else
    echo "All tests passed successfully."
    exit 0
fi
