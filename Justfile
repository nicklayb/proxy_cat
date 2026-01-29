image := "proxy_cat"
current_version := `cat VERSION`
tag := "latest"
user := "nboisvert"

image_tag := image + ":latest"
latest_remote_tag := user / image_tag

version_image_tag := image + ":" + current_version
version_remote_tag := user / version_image_tag

run:
  iex -S mix

docker-build:
  @echo "Building {{image}} v{{current_version}}"
  docker build --build-arg APP_VERSION={{current_version}} -t {{image_tag}} -f ./dockerfiles/Dockerfile .

docker-run: docker-build
  docker run \
    -p $PORT:$PORT \
    -p $BACKEND_PORT:$BACKEND_PORT \
    -e BACKEND_PORT=$BACKEND_PORT \
    -e PORT=$PORT \
    -e UNSPLASH_API_KEY=$UNSPLASH_API_KEY \
    -e CONFIG_YAML=/example.yml \
    --mount type=bind,src=./example.yml,dst=/example.yml \
    {{image_tag}}

docker-tag:
  docker tag {{image_tag}} {{latest_remote_tag}}
  docker tag {{image_tag}} {{version_remote_tag}}

docker-push:
  docker push {{latest_remote_tag}}
  docker push {{version_remote_tag}}

release: docker-build docker-tag docker-push
