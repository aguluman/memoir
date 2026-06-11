# Use Debian Trixie Slim as base for minimal size
FROM debian:trixie-slim AS base

# Install system dependencies including OPAM
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libgmp-dev \
    zlib1g-dev \
    opam \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set up OPAM environment
ENV OPAMROOT=/root/.opam

# Initialize OPAM and install OCaml 5.4.0
RUN opam init --disable-sandboxing --yes && \
    opam switch create 5.4.0 && \
    eval $(opam env --switch=5.4.0)

# Install OCaml dependencies via opam
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

# Set PATH to include the correct switch
ENV PATH=/root/.opam/5.4.0/bin:$PATH

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Build the project
RUN eval $(opam env --switch=5.4.0) && dune build --release

# Generate the static site
RUN make generate

# Expose the port Dream uses by default
EXPOSE 8080

# Default command to run the server
CMD ["make", "serve"]
