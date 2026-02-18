FROM ubuntu:24.04@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9

ENV ARACHNI_TAG=v1.6.1.3
ENV ARACHNI_VERSION=1.6.1.3-0.6.1.1
ENV DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc libc6-dev libffi-dev make ruby ruby-dev && \
    apt-get install -y --no-install-recommends curl wget && \
    gem install gauntlt && \
    sed -i 's/File.exists/File.exist/g' /var/lib/gems/*/gems/gauntlt-*/lib/gauntlt/attack_adapters/support/*_helper.rb && \
    apt-get remove -y gcc libc6-dev libffi-dev make ruby-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Install Attack tools
WORKDIR /opt

# arachni
RUN \
    wget --progress=dot:giga "https://github.com/Arachni/arachni/releases/download/${ARACHNI_TAG}/arachni-${ARACHNI_VERSION}-linux-x86_64.tar.gz" && \
    tar xzf "arachni-${ARACHNI_VERSION}-linux-x86_64.tar.gz" && \
    mv "arachni-${ARACHNI_VERSION}" /usr/local && \
    ln -s "/usr/local/arachni-${ARACHNI_VERSION}/bin/"* /usr/local/bin/ && \
    rm -f "arachni-${ARACHNI_VERSION}-linux-x86_64.tar.gz"

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
