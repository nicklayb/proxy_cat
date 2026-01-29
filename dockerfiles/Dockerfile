# STEP 1 - Build release compiler container
FROM elixir:1.19-otp-28-alpine AS builder

ENV APP_NAME=proxy_cat \
    MIX_ENV=prod

# Install build requirements
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache openssl-dev gcc ca-certificates git

WORKDIR /proxy_cat

RUN mix local.rebar --force && \
    mix local.hex --force

# Compile dependencies and application
COPY . .
RUN mix deps.get --only ${MIX_ENV}
RUN mix compile

# Create a release
RUN mkdir -p /opt/build && \
    mix release && \
    cp -r _build/${MIX_ENV}/rel /opt/build

# STEP 2 - Build application container
FROM alpine:3.23

ARG APP_NAME
ENV APP_NAME=${APP_NAME}

ENV ROOT_FOLDER=/opt

WORKDIR ${ROOT_FOLDER}

# Update kernel and install runtime dependencies
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache gcc bash openssl wget

# Copy the OTP binary from the build step
COPY --from=builder /opt/build .

ENV PATH="/opt/bin/:${PATH}"

COPY dockerfiles/entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/entrypoint.sh
RUN mkdir ${ROOT_FOLDER}/logs

# Create a non-root user
RUN adduser -D proxy_cat && \
    chown -R proxy_cat: ${ROOT_FOLDER}

USER proxy_cat

ENTRYPOINT ["entrypoint.sh"]
CMD ["start"]
