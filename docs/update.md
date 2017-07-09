# To update the AV run the following:

```bash
$ docker run --name=avira malice/avira update
```

## Then to use the updated avira container:

```bash
$ docker commit avira malice/avira:updated
$ docker rm avira # clean up updated container
$ docker run --rm malice/avira:updated EICAR
```
