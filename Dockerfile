# The upstream Arachni release assets were removed. Preserve the installation
# from our last published image, pinned so future image builds cannot change it.
FROM ghcr.io/sjinks/gauntlt@sha256:5bfbc2ec4e0635c6dceb658c3427d0dd9363e8d846ed34b4c3909b3ffdd47028 AS arachni

FROM ubuntu:26.04@sha256:065aa8626841f16057b78b027b464cd59c4fac36c204c72dcbf48d66f5fa8a96

ENV ARACHNI_VERSION=1.6.1.3-0.6.1.1
ENV DEBIAN_FRONTEND=noninteractive

# Gauntlt pins ffi 1.9.18, which cannot compile against Ubuntu 26.04's Ruby.
# Install its dependencies with ffi 1.17 and relax the installed gemspec.
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc libc6-dev libffi-dev make ruby ruby-dev && \
    apt-get install -y --no-install-recommends curl wget \
        libglib2.0-0t64 libnss3 libnspr4 libatk1.0-0t64 libatk-bridge2.0-0t64 \
        libcups2t64 libdrm2 libx11-6 libxcomposite1 libxdamage1 libxext6 \
        libxfixes3 libxrandr2 libgbm1 libxcb1 libxkbcommon0 libpango-1.0-0 \
        libcairo2 libasound2t64 libatspi2.0-0t64 && \
    gem install --no-document aruba:0.7.4 cucumber:1.3.20 ffi:1.17.4 nokogiri trollop && \
    gem install --no-document --ignore-dependencies gauntlt -v 1.0.13 && \
    sed -i 's/"= 1.9.18"/"~> 1.17"/' /var/lib/gems/*/specifications/gauntlt-1.0.13.gemspec && \
    sed -i 's/File.exists/File.exist/g' /var/lib/gems/*/gems/gauntlt-*/lib/gauntlt/attack_adapters/support/*_helper.rb && \
    apt-get remove -y gcc libc6-dev libffi-dev make ruby-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Install Attack tools
WORKDIR /opt

# arachni
COPY --from=arachni /usr/local/arachni-${ARACHNI_VERSION} /usr/local/arachni-${ARACHNI_VERSION}
RUN \
    ln -s "/usr/local/arachni-${ARACHNI_VERSION}/bin/"* /usr/local/bin/

# Nikto
RUN \
    apt-get update && \
    apt-get install -y libtimedate-perl libnet-ssleay-perl && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p nikto && \
    cd nikto && \
    wget https://github.com/sullo/nikto/tarball/master -O - | tar -xz --strip-components=1 -f - && \
    rm -rf .github devdocs documentation && \
    cd program && \
    echo "EXECDIR=/opt/nikto/program" >> nikto.conf && \
    ln -s /opt/nikto/program/nikto.conf /etc/nikto.conf && \
    chmod +x nikto.pl && \
    ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto

# sqlmap
ENV SQLMAP_PATH=/opt/sqlmap/sqlmap.py
RUN \
    mkdir sqlmap && \
    cd sqlmap && \
    wget https://github.com/sqlmapproject/sqlmap/tarball/master -O - | tar -xz --strip-components=1 -f - && \
    rm -rf .github doc

# dirb
ENV DIRB_WORDLISTS=/usr/share/dirb/wordlists
RUN \
    apt-get update && \
    apt-get install -y dirb && \
    rm -rf /var/lib/apt/lists/*

# nmap
RUN apt-get update && \
    apt-get install -y nmap && \
    rm -rf /var/lib/apt/lists/*

# sslyze
ENV SSLYZE_PATH=/usr/local/bin/sslyze
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends python-is-python3 python3 python3-pip && \
    pip install --break-system-packages sslyze && \
    apt-get remove -y python3-pip && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

USER ubuntu
ENTRYPOINT [ "/usr/local/bin/gauntlt" ]
