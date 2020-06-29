# Taken from the shellcheck project
# Build-only image
FROM alpine:3.10 AS build
USER root
WORKDIR /opt/stan

# Install OS deps
RUN apk update && \
        apk add \
            curl \
            gcc g++ gmp-dev libffi-dev make xz tar perl gcc build-base ncurses-dev ncurses-static
RUN ln -sf /usr/lib/libncursesw.so.6.2 /usr/lib/libncursesw.so.6 
RUN ln -sf /usr/lib/libncursesw.so.6 /usr/lib/libtinfow.so.6
RUN ln -sf /usr/lib/libtinfow.so.6 /usr/lib/libtinfow.so
RUN ln -sf /usr/lib/libncursesw.a /usr/lib/libtinfow.a

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
ARG ghc_version_arg=8.10.1
ENV ghc_version=$ghc_version_arg
RUN ~/.ghcup/bin/ghcup install $ghc_version
RUN ~/.ghcup/bin/ghcup install-cabal 3.2.0.0
ENV PATH="${PATH}:/root/.ghcup/bin"

# Install Haskell deps
# (This is a separate copy/run so that source changes don't require rebuilding)
COPY stan.cabal ./
RUN cabal update && cabal build --write-ghc-environment-files=always --dependencies-only --ghc-options="-optlo-Os -split-sections"

# Copy source and build it
COPY LICENSE CHANGELOG.md README.md ./
COPY src src
COPY app app
COPY target target
COPY test test
RUN cabal build --write-ghc-environment-files=always Paths_Stan lib:stan
# RUN cabal build --ghc-options="-optl-static -optl-pthread -split-sections -optc-Wl,--gc-sections -optlo-Os" --write-ghc-environment-files=always exe:stan
RUN ghc -static -optl-static -optl-pthread -split-sections --make app/Main.hs -o stan

RUN mkdir -p /out/bin && \
  cp stan /out/bin/

# Resulting Stan image
FROM scratch
LABEL maintainer="Thomas DuBuisson <thomas.dubuisson@gmail.com>"
WORKDIR /mnt
COPY --from=build /out/bin/stan /stan
ENTRYPOINT ["/stan"]
