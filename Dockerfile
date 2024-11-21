# ================================
# Build image
# ================================
FROM swift:5.8-jammy as build

# Install OS updates and dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y openssl libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First, configure GitHub authentication for private repositories
ARG GITHUB_USERNAME
ARG GITHUB_TOKEN
RUN git config --global url."https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"

# Resolve dependencies
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into the container
COPY . .

# Build everything, with optimizations
RUN swift build -c release --static-swift-stdlib

# Prepare the staging area
WORKDIR /staging

# Copy main executable and resources
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/App" ./
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Resources ] && { mv /build/Resources ./Resources && chmod -R a-w ./Resources; } || true

# ================================
# Run image
# ================================
FROM ubuntu:jammy

# Install essential packages
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create a vapor user
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app

# Copy built executable and resources from the builder
COPY --from=build --chown=vapor:vapor /staging /app

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
