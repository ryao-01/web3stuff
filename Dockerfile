FROM debian:stable-slim 
LABEL author="richard.yao@antithesis.com"
LABEL description="web3 stuff"

COPY . /web3stuff
WORKDIR /web3stuff

RUN apt-get update \
  && apt-get --yes upgrade \
  && apt-get install --yes --no-install-recommends libssl-dev ca-certificates jq git curl make grep nodejs npm \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # Pull and install Foundry
  && curl --silent --location --proto "=https" https://foundry.paradigm.xyz | bash \
  && /root/.foundry/bin/foundryup \
  && cp /root/.foundry/bin/* /usr/local/bin \
  # Smart contract stuff (deploy before polymarket)
  && git clone --branch main https://github.com/ryao-01/proxy-factories.git \
  # Polymarket stuff
  && git clone --branch main https://github.com/ryao-01/ctf-exchange.git 
  
# Install web3.js and other npm dependencies 
RUN npm install web3 
# Optional verification steps 
RUN node -e "try { require('web3'); console.log('web3.js installed successfully'); } catch (e) { console.error('web3.js installation failed', e); process.exit(1); }"