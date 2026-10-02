# Python 3.12 base

This base is used by MLBIO for geometric-curriculum's unified Python 3.12
training and GPU representation metrics environment. The independent 3.11 and
3.13 image chains are unchanged.

Python lives in `/opt/venv`. The CUDA 12.2 development toolkit is retained;
the project uses the official prebuilt FlashAttention CPython 3.12 wheel with
PyTorch 2.8's bundled CUDA 12.8 runtime. No FlashAttention source build is used.
Cluster GPU drivers must support CUDA 12.8. Toolkit compatibility for any future
custom CUDA extension build must be checked separately.

The `base-py312` workflow publishes this base first. Its successful completion
triggers `mlbio`, avoiding an initial-build race. Dispatch `mlbio` manually for
MLBIO-only changes. Python ML dependencies are installed from the project's
requirements lock at job startup, not baked into these images.
