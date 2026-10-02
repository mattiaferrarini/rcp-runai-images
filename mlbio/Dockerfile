ARG BASE_IMAGE="ghcr.io/mattiaferrarini/rcp-runai-images/base-py312:master"
FROM ${BASE_IMAGE}

# Inherit one Python 3.12 environment at /opt/venv. ML dependencies are
# installed from geometric-curriculum's lockfile at job startup, not baked in.

# The mlbio-scratch PVC is mounted here by the RunAI submission command.
ENV USER_HOME_ROOT="/mnt/mlbio/scratch"

# Copy the configurable entrypoint explicitly so this image is correct even
# when it is built concurrently with an updated base-py312 image.
COPY base-py312/user-entrypoint.sh /tmp/user-entrypoint.sh
COPY mlbio/.bashrc /tmp/.bashrc
RUN chmod +x /tmp/user-entrypoint.sh

ENTRYPOINT ["/tmp/user-entrypoint.sh"]
CMD ["/bin/bash"]
