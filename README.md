# Stickman-Dev Kodi Add-ons

Add this repository to Kodi to download the Kodi add-ons and keep them up to date.

## Installing

1. In Kodi, add a file source pointing at `https://stickman-dev.github.io/repository.stickman-dev.plugins/`
2. Settings -> Add-ons -> Install from zip file -> pick that source -> install `repository.stickman-dev.plugins-1.0.0.zip`
3. Once installed, go to Install from repository -> Stickman-Dev Add-on Repository -> VPN Manager for OpenVPN

## Publishing a new addon version

From this repo: `./publish.sh ../service.vpn.manager` (after bumping the version in `service.vpn.manager/addon.xml` and pushing it).

## Publishing a new repository version

Bump the version in `repo/repository.stickman-dev.plugins/addon.xml`, rebuild `repository.stickman-dev.plugins-<version>.zip` at the repo root from `repo/repository.stickman-dev.plugins/`, and update the link in `index.html`.
