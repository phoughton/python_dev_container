# Python Development Container
Use as a template for python dev container.

This will add some useful tools and shortcuts to the standard VSCode Python dev image.


## Using the Dockerfile to create an image

We might want to do this to support additions & updates to the tools included in the container image.

Follow these steps:

```
# Find the docker file
cd /.devcontainer

# To build the image
docker build -t phoughton/python-dev-main

# Login to existing account
docker login

# Upload
docker push phoughton/python-dev-main
```
