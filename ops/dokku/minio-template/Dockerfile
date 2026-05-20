FROM minio/minio:latest

EXPOSE 9000 9001

ENTRYPOINT ["minio"]
CMD ["server", "/app/storage", "--console-address", ":9001"]
