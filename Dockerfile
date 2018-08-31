FROM nimlang/nim

RUN mkdir /home/app
COPY . /home/app
WORKDIR /home/app

RUN nimble install

EXPOSE 80
ENTRYPOINT [ "/home/app/espnff" ]