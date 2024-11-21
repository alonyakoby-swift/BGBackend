# ================================
# Build image
# ================================
FROM swift:5.8-jammy as build

# Install required libraries
RUN apt-get update -y && apt-get install -y \
    openssl libssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy dependencies and resolve them
COPY ./Package.* ./
RUN swift package resolve

# Copy the full source code
COPY . .

# Build the application
RUN swift build -c release --static-swift-stdlib

# Prepare the staging area
WORKDIR /staging
RUN cp "$(swift build -c release --show-bin-path)/App" ./
RUN find "$(swift build -c release --show-bin-path)/" -name '*.resources' -exec cp -R {} ./ \;

# ================================
# Run image
# ================================
FROM ubuntu:jammy

# Install runtime libraries
RUN apt-get update -y && apt-get install -y \
    ca-certificates tzdata libcurl4 && \
    rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd --user-group --create-home --system vapor

WORKDIR /app
COPY --from=build --chown=vapor:vapor /staging /app

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
