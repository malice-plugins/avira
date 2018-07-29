# avira

[![Circle CI](https://circleci.com/gh/malice-plugins/avira.png?style=shield)](https://circleci.com/gh/malice-plugins/avira)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
[![Docker Stars](https://img.shields.io/docker/stars/malice/avira.svg)](https://store.docker.com/community/images/malice/avira)
[![Docker Pulls](https://img.shields.io/docker/pulls/malice/avira.svg)](https://store.docker.com/community/images/malice/avira)
[![Docker Image](https://img.shields.io/badge/docker%20image-405MB-blue.svg)](https://store.docker.com/community/images/malice/avira)

Malice [Avira](https://www.avira.com) AntiVirus Plugin

### Dependencies

- [ubuntu:xenial (_118 MB_\)](https://hub.docker.com/_/ubuntu/)

### Installation

1.  Install [Docker](https://www.docker.io/).
2.  Download [trusted build](https://store.docker.com/community/images/malice/avira) from public [DockerHub](https://hub.docker.com): `docker pull malice/avira`

### Usage

```
docker run --rm -v `pwd`/hbedv.key:/opt/avira/hbedv.key malice/avira EICAR
```

> **NOTE:** I am mounting my **license key** into the docker container at run time

#### Or link your own malware folder:

```bash
$ docker run --rm -v /path/to/malware:/malware:ro malice/avira FILE

Usage: avira [OPTIONS] COMMAND [arg...]

Malice Avira AntiVirus Plugin

Version: v0.1.0, BuildTime: 20170910

Author:
  blacktop - <https://github.com/blacktop>

Options:
  --verbose, -V         verbose output
  --table, -t	        output as Markdown table
  --callback, -c	    POST results to Malice webhook [$MALICE_ENDPOINT]
  --proxy, -x	        proxy settings for Malice webhook endpoint [$MALICE_PROXY]
  --timeout value       malice plugin timeout (in seconds) (default: 60) [$MALICE_TIMEOUT]
  --elasitcsearch value elasitcsearch address for Malice to store results [$MALICE_ELASTICSEARCH]
  --help, -h	        show help
  --version, -v	        print the version

Commands:
  update	Update virus definitions
  web       Create a avira scan web service
  help		Shows a list of commands or help for one command

Run 'avira COMMAND --help' for more information on a command.
```

This will output to stdout and POST to malice results API webhook endpoint.

## Sample Output

### [JSON](https://github.com/malice-plugins/avira/blob/master/docs/results.json)

```json
{
  "avira": {
    "infected": true,
    "result": "Eicar-Test-Signature",
    "engine": "8.3.44.100",
    "updated": "20170709"
  }
}
```

### [Markdown](https://github.com/malice-plugins/avira/blob/master/docs/SAMPLE.md)

---

#### Avira

| Infected |        Result        |   Engine   | Updated  |
| :------: | :------------------: | :--------: | :------: |
|   true   | Eicar-Test-Signature | 8.3.44.100 | 20170709 |

---

## Documentation

- [To use your own license key](https://github.com/malice-plugins/avira/blob/master/docs/license.md)
- [To write results to ElasticSearch](https://github.com/malice-plugins/avira/blob/master/docs/elasticsearch.md)
- [To create a Avira scan micro-service](https://github.com/malice-plugins/avira/blob/master/docs/web.md)
- [To post results to a webhook](https://github.com/malice-plugins/avira/blob/master/docs/callback.md)
- [To update the AV definitions](https://github.com/malice-plugins/avira/blob/master/docs/update.md)

## Issues

Find a bug? Want more features? Find something missing in the documentation? Let me know! Please don't hesitate to [file an issue](https://github.com/malice-plugins/avira/issues/new).

## TODO

- [ ] add docs on how to get a license key [:wink:](https://github.com/malice-plugins/avira/blob/master/NOTES.md)

## CHANGELOG

See [`CHANGELOG.md`](https://github.com/malice-plugins/avira/blob/master/CHANGELOG.md)

## Contributing

[See all contributors on GitHub](https://github.com/malice-plugins/avira/graphs/contributors).

Please update the [CHANGELOG.md](https://github.com/malice-plugins/avira/blob/master/CHANGELOG.md) and submit a [Pull Request on GitHub](https://help.github.com/articles/using-pull-requests/).

## License

MIT Copyright (c) 2016 **blacktop**
