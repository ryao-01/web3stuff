FROM debian:stable-slim 
LABEL author="richard.yao@antithesis.com"
LABEL description="web3 stuff"

# Set Go version
ARG GO_VERSION=1.22.11

#polycli ver
ARG GIT_BRANCH="v0.1.73"

WORKDIR /web3stuff

#Install updates and grab repos
RUN apt-get update -y

RUN apt-get --yes upgrade \
  && apt-get install --yes --no-install-recommends libssl-dev ca-certificates jq bc git curl wget gcc libc-dev make grep nodejs npm protobuf-compiler \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # Smart contract stuff (deploy before polymarket)
  && git clone --branch main https://github.com/ryao-01/proxy-factories.git \
  # Polymarket stuff
  && git clone --branch main https://github.com/ryao-01/ctf-exchange.git 

# Install Go
RUN wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz 
RUN tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz 
ENV PATH=$PATH:/usr/local/go/bin
# # Verify Go installation
RUN go version 

# Install Polycli 
RUN git clone https://github.com/0xPolygon/polygon-cli.git && cd polygon-cli && git checkout ${GIT_BRANCH} 
WORKDIR polygon-cli
RUN go clean -modcache
RUN go mod tidy
RUN export PATH="$HOME/go/bin:$PATH"
RUN make install

WORKDIR /web3stuff
# Pull and install Foundry
RUN curl --silent --location --proto "=https" https://foundry.paradigm.xyz | bash \
  && /root/.foundry/bin/foundryup \
  && cp /root/.foundry/bin/* /usr/local/bin 

RUN forge init --no-git --force 

# Install web3.js and other npm dependencies 
RUN npm install web3 
# Optional verification steps 
RUN node -e "try { require('web3'); console.log('web3.js installed successfully'); } catch (e) { console.error('web3.js installation failed', e); process.exit(1); }"

# Install Polymarket dependencies using forge (foundry)
RUN forge install OpenZeppelin/openzeppelin-contracts@v4.7.3 --no-git
RUN forge install OpenZeppelin/openzeppelin-solidity --no-git
RUN forge install gnosis/safe-contracts@v1.3.0 --no-git
RUN forge install transmissions11/solmate --no-git
RUN forge install gnosis/conditional-tokens-contracts --no-git

# Install solc native binaries
RUN mkdir -p ~/.foundry/solc
RUN curl -L https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.5.1+commit.c8a2cb62 -o ~/.foundry/solc/solc-0.5.1
RUN curl -L https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.8.15+commit.e14f2714 -o ~/.foundry/solc/solc-0.8.15
COPY solc-static-linux-0.8.28 ~/.foundry/solc/solc-0.8.28
RUN chmod +x ~/.foundry/solc/solc-*

# Set up foundry.toml to use native solc
RUN sed -i '/^\[profile.default\]/a auto_detect_solc = true' foundry.toml

COPY /src /web3stuff/src 
COPY remappings.txt /web3stuff/