# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

FROM arm32v7/ubuntu:latest

ENV PS_VERSION=7.2.1
ENV PS_PACKAGE=powershell-${PS_VERSION}-linux-arm32.tar.gz
ENV PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}

RUN \
  apt-get clean \
  && apt-get update \
  && apt-get install --no-install-recommends tzdata ca-certificates libunwind8 '^libssl1.0.[0-9]$' libicu66 less wget --yes \
  && wget https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE} \
  && mkdir ~/powershell \
  && tar -xvf ./${PS_PACKAGE} -C ~/powershell \
  && ln -s /root/powershell/pwsh /usr/bin/pwsh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN \
  echo "export WIRINGPI_CODES=1"|tee -a /etc/profile.d/WiringPiCodes.sh

RUN \
  pwsh -NoProfile -ExecutionPolicy Bypass -Command "Install-Module -Name Microsoft.PowerShell.IoT, PoSHue -Scope AllUsers -Force -Confirm:0"

COPY opto-docker.ps1 /bin/

ENTRYPOINT ["pwsh","-File","/bin/opto-docker.ps1"]
