FROM kalilinux/kali-rolling:latest@sha256:6ec743d9fc5cd397451eeddeff3869bcfab5de9bd5dec5b1f34cbfbd80313073

ENV DEBIAN_FRONTEND=noninteractive

# Gauntlt pins ffi 1.9.18, which cannot compile against Ubuntu 26.04's Ruby.
# Install its dependencies with ffi 1.17 and relax the installed gemspec.
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc libc6-dev libffi-dev make ruby ruby-dev && \
    apt-get install -y --no-install-recommends curl wget && \
    gem install --no-document aruba:0.7.4 cucumber:1.3.20 ffi:1.17.4 nokogiri trollop && \
    gem install --no-document --ignore-dependencies gauntlt -v 1.0.13 && \
    sed -i 's/"= 1.9.18"/"~> 1.17"/' /var/lib/gems/*/specifications/gauntlt-1.0.13.gemspec && \
    sed -i 's/File.exists/File.exist/g' /var/lib/gems/*/gems/gauntlt-*/lib/gauntlt/attack_adapters/support/*_helper.rb && \
    apt-get remove -y gcc libc6-dev libffi-dev make ruby-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Install Attack tools
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends wapiti nikto sqlmap dirb nmap sslyze && \
    apt-get install -y libcap2-bin python-is-python3 && \
    rm -rf /var/lib/apt/lists/* && \
    setcap cap_net_raw,cap_net_bind_service+ep /usr/lib/nmap/nmap

ENV DIRB_WORDLISTS=/usr/share/dirb/wordlists
ENV SSLYZE_PATH=/usr/bin/sslyze

RUN useradd -m -s /bin/bash kali

USER kali
ENTRYPOINT [ "/usr/local/bin/gauntlt" ]
