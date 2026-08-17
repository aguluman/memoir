FROM debian:trixie-slim AS base

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libgmp-dev \
    zlib1g-dev \
    opam \
    make \
    && rm -rf /var/lib/apt/lists/*

ENV OPAMROOT=/root/.opam

RUN opam init --disable-sandboxing --yes && \
    opam switch create 5.4.0 && \
    eval $(opam env --switch=5.4.0)

RUN eval $(opam env --switch=5.4.0) && \
    opam install --yes \
    dune \
    yaml \
    tyxml \
    omd \
    dream \
    alcotest \
    qcheck \
    qcheck-alcotest

ENV PATH=/root/.opam/5.4.0/bin:$PATH

WORKDIR /app

COPY . .

RUN eval $(opam env --switch=5.4.0) && dune build --release

RUN make generate

EXPOSE 8080

CMD ["make", "serve"]
