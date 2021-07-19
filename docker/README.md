# Probetest docker image

This repository contains the docker files for our probe test

## Releasing a new image

First, build the image:

```
make build
```

Note: make sure that there is a file called `bridge_lines.txt` in the `docker/` directory. This will bake obfs4 bridge lines into the probe test image.

Next, release a new version by adding a tag:

    make tag VERSION=X.Y

Finally, release the image:

    make release VERSION=X.Y

Once we released a new image version, we tag the respective git commit:

    git tag -a -s "vVERSION" -m "Docker image version VERSION."
    git push --tags origin main
