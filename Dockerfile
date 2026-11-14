FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
# Telegram itself lives in ./bin on the host (run.sh seeds it), so this image is only the
# runtime. Wayland libs are dlopen'd, so ldd misses them. Firefox opens links; Ubuntu's
# package is a snap stub, so it comes from Mozilla's repo. waypipe carries Wayland out of the VM.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && install -d /etc/apt/keyrings \
 && curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/mozilla.asc \
 && echo 'deb [signed-by=/etc/apt/keyrings/mozilla.asc] https://packages.mozilla.org/apt mozilla main' > /etc/apt/sources.list.d/mozilla.list \
 && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla \
 && apt-get update \
 && apt-get install -y --no-install-recommends firefox waypipe \
      libwayland-client0 libwayland-cursor0 libwayland-egl1 libwayland-server0 libegl1 libgbm1 libopengl0 libgl1 libxkbcommon0 \
      libasound2t64 libx11-6 libxext6 libxrender1 libxcb1 libxcb-render0 libxcb-shm0 \
      libglib2.0-0t64 libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 \
      libfreetype6 libfontconfig1 libharfbuzz0b zlib1g \
      fonts-noto-cjk fontconfig ca-certificates xdg-utils \
 && apt-get purge -y --auto-remove curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists
