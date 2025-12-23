image := "unsplash-proxy"
tag := "latest"
image_tag := image + ":" + tag
remote_tag := "nboisvert" / image_tag

run:
  iex -S mix

docker-build:
  docker build -t {{image_tag}} -f ./dockerfiles/Dockerfile .

docker-run: docker-build
  docker run -p $PORT:$PORT -e PORT=$PORT -e UNSPLASH_API_KEY=$UNSPLASH_API_KEY unsplash_proxy:latest

docker-tag:
  docker tag {{image_tag}} {{remote_tag}}

docker-push:
  docker push {{remote_tag}}

release: docker-build docker-tag docker-push
