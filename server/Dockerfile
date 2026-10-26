# Whowolf relay server. Build from the repository root:
#   docker build -f server/Dockerfile -t whowolf-relay .
FROM dart:3.12.2 AS build
WORKDIR /src

# Resolve dependencies first (cached unless a pubspec changes). The Flutter
# app, the encryption layer and the command-line client are not part of this
# image (the relay only forwards ciphertext), so they leave the workspace.
COPY pubspec.yaml pubspec.lock ./
COPY packages/game_core/pubspec.yaml packages/game_core/
COPY packages/protocol/pubspec.yaml packages/protocol/
COPY packages/game_host/pubspec.yaml packages/game_host/
COPY server/pubspec.yaml server/
RUN sed -i -e '/^  - app$/d' -e '/^  - packages\/secure_channel$/d' -e '/^  - packages\/cli$/d' pubspec.yaml \
    && dart pub get

COPY packages packages
COPY server server
RUN mkdir -p /out && dart compile exe server/bin/server.dart -o /out/whowolf-relay

# Minimal runtime: the compiled binary and the Dart runtime libraries only,
# no shell, running as an unprivileged user.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /out/whowolf-relay /app/whowolf-relay
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/whowolf-relay"]
