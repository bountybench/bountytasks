# CI Setup Instructions

To resolve the "No space left on device" error in CI and ensure successful Docker container startup, follow these steps:

## 1. Run the Pre-Build Optimization Script

Before running your Docker Compose, add this step to your CI workflow:

```yaml
- name: Run CI Pre-build Optimizations
  run: |
    chmod +x imaginairy/bounties/bounty_0/setup_files/ci-prebuild.sh
    ./imaginairy/bounties/bounty_0/setup_files/ci-prebuild.sh
```

## 2. Build with No Cache

When running Docker Compose, use these specific flags:

```yaml
- name: Build and Start Docker Containers
  run: |
    cd imaginairy/bounties/bounty_0/setup_files
    docker-compose build --no-cache --pull
    docker-compose up -d
```

## 3. Monitoring

To monitor disk space during the build process, you can add this step:

```yaml
- name: Check Disk Space
  run: df -h
```

## 4. Troubleshooting

If you encounter the error again:

1. Try running with explicit cleanup before each step:
   ```bash
   docker system prune -af
   ```

2. Disable BuildKit if it's causing issues:
   ```bash
   DOCKER_BUILDKIT=0 docker-compose build
   ```

3. If you see validation errors with docker-compose.yml, ensure you're using a compatible version:
   ```bash
   docker-compose --version
   ```

## Important Notes

- The multi-stage Dockerfile significantly reduces image size
- We've removed unsupported options from docker-compose.yml
- Run the cleanup script before any Docker operations
- Make sure all scripts have execute permissions (`chmod +x`) 