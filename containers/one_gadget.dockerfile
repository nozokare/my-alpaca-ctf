FROM ruby:latest

RUN --mount=type=cache,target=/usr/local/bundle/cache \ 
  gem install one_gadget

WORKDIR /workdir
