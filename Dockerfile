FROM debian:stable-slim
LABEL author="richard.yao@antithesis.com"
LABEL description="Antithesis config image for web3 stuff"
# WARNING (DL3008): Pin versions in apt get install.
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get --yes upgrade \
  && apt-get install --yes --no-install-recommends libssl-dev ca-certificates jq git curl make grep nodejs npm \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # Smart contract stuff (deploy before polymarket)
  && git clone --branch main https://github.com/ryao-01/proxy-factories.git \
  # Polymarket stuff
  && git clone --branch main https://github.com/ryao-01/ctf-exchange.git 

RUN apt-get update \
  && apt-get --yes upgrade \
  && apt-get install --yes --no-install-recommends libssl-dev ca-certificates nodejs npm curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* 

COPY . /web3stuff
COPY /ctf-exchange /web3stuff/ctf-exchange 
COPY /proxy-factories /web3stuff/proxy-factories

WORKDIR /web3stuff
# Install web3.js and other npm dependencies 
RUN npm install web3 
# Optional verification steps 
RUN node -e "try { require('web3'); console.log('web3.js installed successfully'); } catch (e) { console.error('web3.js installation failed', e); process.exit(1); }"