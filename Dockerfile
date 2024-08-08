# Use the official Rust image as the builder
FROM rust:1.70-alpine AS builder

# Install build dependencies
RUN apk add --no-cache musl-dev

# Create a new empty shell project
RUN USER=root cargo new --bin claude-api-chef
WORKDIR /claude-api-chef

# Copy manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# Build dependencies - this is the caching Docker layer!
RUN cargo build --release
RUN rm src/*.rs

# Copy source tree
COPY ./src ./src

# Build for release
RUN rm ./target/release/deps/claude_api_chef*
RUN cargo build --release

# Final stage
FROM alpine:latest

ARG APP=/usr/src/app
EXPOSE 8000

ENV TZ=Etc/UTC \
    APP_USER=appuser

RUN addgroup -S $APP_USER \
    && adduser -S -g $APP_USER $APP_USER

RUN apk update \
    && apk add --no-cache ca-certificates tzdata \
    && rm -rf /var/cache/apk/*

COPY --from=builder /claude-api-chef/target/release/claude-api-chef ${APP}/claude-api-chef

RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER
WORKDIR ${APP}

CMD ["./claude-api-chef"]
