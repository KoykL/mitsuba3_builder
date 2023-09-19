FROM registry.access.redhat.com/ubi8/ubi:8.8-1032.1692772289 AS builder
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && dnf groupinstall -y "Development Tools" && dnf install -y python3.11 python3.11-devel python3.11-pip cmake ninja-build libatomic ccache gcc-toolset-10  && dnf clean all
RUN pip3.11 install --no-cache-dir scikit-build
COPY . /mitsuba
WORKDIR /mitsuba
ENV CCACHE_DIR=/ccache
#    CC="ccache gcc" CXX="ccache g++"
ARG NLTO=auto
RUN --mount=type=cache,target=/ccache cd ext/pybind11 && rm -rf dist && CMAKE_CXX_COMPILER_LAUNCHER=ccache scl enable gcc-toolset-10 'bash -c "python3.11 setup.py bdist_wheel && pip3.11 install ./dist/*.whl"'
# --mount=type=cache,target=/mitsuba/ext/drjit/_skbuild 
RUN --mount=type=cache,target=/ccache cd ext/drjit && rm -rf dist  && CMAKE_CXX_COMPILER_LAUNCHER=ccache scl enable gcc-toolset-10 'bash -c "python3.11 setup.py bdist_wheel -- -DCMAKE_C_FLAGS=-flto=${NLTO} -DCMAKE_CXX_FLAGS=-flto=${NLTO} && pip3.11 install ./dist/*.whl"'
# --mount=type=cache,target=/mitsuba/_skbuild 
RUN --mount=type=cache,target=/ccache rm -rf dist && CMAKE_CXX_COMPILER_LAUNCHER=ccache scl enable gcc-toolset-10 'bash -c "python3.11 setup.py bdist_wheel -- -DCMAKE_C_FLAGS=-flto=${NLTO} -DCMAKE_CXX_FLAGS=-flto=${NLTO}"'
FROM scratch AS wheels
COPY --from=builder /mitsuba/dist/*.whl /
COPY --from=builder /mitsuba/ext/drjit/dist/*.whl /