FROM ruby:3.0.1 AS builder

RUN apt-get update -y
RUN apt-get install -y libtool-bin
RUN wget http://www.leonerd.org.uk/code/libvterm/libvterm-0.1.4.tar.gz && tar xzvf libvterm-0.1.4.tar.gz && cd libvterm-0.1.4 && make install
WORKDIR /msh
COPY . /msh
RUN cd third_party/mruby && rake clean
RUN bundle install
RUN bundle exec rake clean install mruby spec

FROM ubuntu:20.04
WORKDIR /msh
COPY --from=builder /msh/bin/msh /app/
CMD ["/app/msh"]
