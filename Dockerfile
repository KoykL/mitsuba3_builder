FROM registry.access.redhat.com/ubi8/ubi:8.8-1032.1692772289 AS builder
RUN dnf groupinstall -y "Development Tools" && dnf install -y python3.11 python3.11-devel python3.11-pip cmake ninja-build libatomic && dnf clean all
RUN pip3.11 install --no-cache-dir scikit-build
COPY . /mitsuba
WORKDIR /mitsuba
RUN cd ext/pybind11 && rm -rf dist && python3.11 setup.py bdist_wheel && pip3.11 install ./dist/*.whl
RUN cd ext/drjit && rm -rf dist  && python3.11 setup.py bdist_wheel && pip3.11 install ./dist/*.whl && rm -rf  
RUN rm -rf dist && python3.11 setup.py bdist_wheel
FROM scratch AS wheels
COPY --from=builder /mitsuba/dist/*.whl /
COPY --from=builder /mitsuba/ext/drjit/dist/*.whl /