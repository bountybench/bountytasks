import os
import pytest
import json

def find_missing_docker_health_checks(modified_dirs):
    """
    Validate Docker health checks for modified repositories.
    
    Args:
        modified_dirs (list): List of modified repository directories
    
    Returns:
        dict: A dictionary of repositories and their missing health check files
    """
    missing_health_checks = {}

    for repo_dir in modified_dirs:
        # Ensure this is a repository with bounties
        if not os.path.isdir(os.path.join(repo_dir, 'bounties')):
            continue

        # Check repo-level docker-compose
        repo_compose_path = os.path.join(repo_dir, 'docker-compose.yml')
        repo_name = os.path.basename(repo_dir)

        # First check repo-level docker-compose
        if os.path.exists(repo_compose_path):
            with open(repo_compose_path, 'r') as f:
                content = f.read()
                if 'healthcheck:' not in content:
                    missing_health_checks[repo_name] = [repo_compose_path]
                continue

        # If no repo-level compose, check bounty docker-compose files
        bounty_missing_checks = []
        for root, _, files in os.walk(os.path.join(repo_dir, 'bounties')):
            if 'docker-compose.yml' in files:
                bounty_compose_path = os.path.join(root, 'docker-compose.yml')
                with open(bounty_compose_path, 'r') as f:
                    content = f.read()
                    if 'healthcheck:' not in content:
                        bounty_missing_checks.append(bounty_compose_path)

        if bounty_missing_checks:
            missing_health_checks[repo_name] = bounty_missing_checks

    return missing_health_checks

def test_docker_health_checks(request):
    """
    Test Docker health checks in modified repositories.
    
    Reads modified directories from pytest configuration and validates 
    Docker health checks.
    """
    # Retrieve the modified directories
    dirs = request.config.getoption("--dirs")
    if not dirs:
        pytest.skip("No modified directories specified")

    # Split the directories and add full path
    modified_dirs = [os.path.join(os.getcwd(), d.strip()) if isinstance(d, str) else d for d in dirs]

    # Find missing health checks
    missing_checks = find_missing_docker_health_checks(modified_dirs)

    # If any missing health checks, fail the test and provide detailed report
    if missing_checks:
        report = "Docker Health Check Validation Failed:\n"
        for repo, compose_files in missing_checks.items():
            report += f"\nRepository: {repo}\n"
            report += "Missing Health Checks in:\n"
            for file in compose_files:
                report += f"  - {os.path.relpath(file)}\n"
            report += "\nExample Health Check Configuration:\n"
            report += "services:\n"
            report += "  app:\n"
            report += "    image: your-image\n"
            report += "    healthcheck:\n"
            report += "      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8000/health\"]\n"
            report += "      interval: 30s\n"
            report += "      timeout: 10s\n"
            report += "      retries: 3\n"

        pytest.fail(report)