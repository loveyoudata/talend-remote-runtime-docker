# Talend Remote Engine in Docker

:warning: **This repository has just been quickly hacked together as a proof of concept and is not officially supported by [Talend, Inc.](https://github.com/Talend)**

This repository contains a basic `Dockerfile` to show how a remote engine can be run in Docker. In order to build this image, you have to log in to the [Talend Portal](https://portal.eu.cloud.talend.com/) and download the *Archive for Linux (tar.gz)* in the desired version into the `remote-engine/` subfolder.

```bash
# When setting the version, make sure the exact string is contained in the Talend Remote Engine archive's name
# Usually the archive name resembles to "Talend-RemoteEngine-V<X>.<Y>.<Z>-<BUILD_NUMBER>.tar.gz"
export TALEND_RE_VERSION="2.14.0"
cd ..
docker build -t hpmanoj/talend-remote-engine-runtime:${TALEND_RE_VERSION} --build-arg TALEND_RE_VERSION=${TALEND_RE_VERSION} .

```

Start a container from your newly built image. Simply place your environment variables in a dedicated file (see `example.env` in this repository). Don't forget to persist the Engine's configuration to be able to connect on a container restart.

```bash
docker run -d --env-file .env --volume "remote-engine-data:/opt/talend/remote-engine/etc" hpmanoj/talend-remote-engine-runtime:${TALEND_RE_VERSION}
```

Alternatively export the values to your environment and pass them along.

```bash
export TALEND_RE_KEY="<Your super secret pairing key>"
export TALEND_RE_NAME="<Name of your Remote Engine>"
export TALEND_RE_DESC="<Some descriptive words>"
# One of eu, us, ap, us-west
export TALEND_RE_REGION=eu
docker run -d --env TALEND_RE_KEY --env TALEND_RE_NAME --env TALEND_RE_DESC --env TALEND_RE_REGION --volume "remote-engine-data:/opt/talend/remote-engine/etc" hpmanoj/talend-remote-engine-runtime:${TALEND_RE_VERSION}
```
s


-------
# Mount your local folder instead of a named volume (using $PWD for current directory)
docker run -d --env-file example.env --volume "$PWD/remote-engine/etc:/opt/talend/remote-engine/etc" --volume "$PWD/runtime-engine/etc:/opt/talend/runtime-engine/etc" --volume "$PWD/software:/opt/software" hpmanoj/talend-remote-engine-runtime:2.14.0

-------

```bash
# 1. Stop the container if it's running
docker stop <container_name_or_id>

# 2. Remove the container (keep the volume)
docker rm <container_name_or_id>

# 3. Run it again with the same command
docker run -d --env-file .env --volume "remote-engine-data:/opt/talend/remote-engine/etc" --volume "remote-engine-data:/opt/talend/runtime-engine/etc" hpmanoj/talend-remote-engine-runtime:2.14.0
```

-------
Attach into the shell
docker exec -it <container_name_or_id> bash

-------

## Applying a Runtime Patch

To apply a patch to the Talend Runtime Engine (e.g. `Patch_20260213_R2026-02_v2-RT-8.0.1.R2025-02-RT.zip`), follow these steps while the container is running:

1. Ensure the patch zip file is in your `software` folder (which is mounted to `/opt/software` inside the container).
2. Connect to the running container's shell:
   ```bash
   docker exec -it <container_name_or_id> bash
   ```
3. Inside the container, extract the patch and apply it:
   ```bash
   # Create a temporary directory for extraction
   mkdir -p /tmp/patch
   cd /tmp/patch
   
   # Extract the patch using the 'jar' command (since 'unzip' is not installed)
   jar xf /opt/software/Patch_20260213_R2026-02_v2-RT-8.0.1.R2025-02-RT.zip
   
   # Copy the extracted patch files into the runtime engine directory
   cp -r container/* /opt/talend/runtime-engine/
   
   # Navigate to the patch directory
   cd /opt/talend/runtime-engine/patches/Patch_20260213_R2026-02_v2-RT-8.0.1.R2025-02-RT
   
   # Make the patch script executable
   chmod +x patch.sh
   
   # Execute the patch. We use --auto-fix-default-passwords in case you are using the default tadmin credentials.
   ./patch.sh --auto-fix-default-passwords
   ```
4. Check the logs in the `/opt/talend/runtime-engine/patches/.../logs/` directory to ensure the patch was successfully installed.

-------

## Extracting Default Configuration

Before running the final container with volume mounts, you might want to extract the default configuration files to your local host so you can edit them (e.g., adding credentials or custom properties) before starting the engine.

You can do this by using a temporary container:

```bash
# 1. Create a temporary container (without starting it)
docker create --name tmp-talend-engine hpmanoj/talend-remote-engine-runtime:2.14.0

# 2. Ensure your local directories exist
mkdir -p "$PWD/remote-engine/etc"
mkdir -p "$PWD/runtime-engine/etc"

# 3. Copy the default configurations from the container to your host
docker cp tmp-talend-engine:/opt/talend/remote-engine/etc.default/. "$PWD/remote-engine/etc/"
docker cp tmp-talend-engine:/opt/talend/runtime-engine/etc.default/. "$PWD/runtime-engine/etc/"

# 4. Remove the temporary container
docker rm tmp-talend-engine
```

After doing this, you can safely modify the configuration files locally. When you run the `docker run` command with `--volume "$PWD/remote-engine/etc:/opt/talend/remote-engine/etc"`, the container will use your locally extracted and modified files.
