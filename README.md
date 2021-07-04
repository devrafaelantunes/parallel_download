# ParallelDownload

`ParallelDownload` is a tool to perform an arbitrary number of GET requests concurrently.

## Install

```sh
git clone https://github.com/devrafaelantunes/parallel_download.git
cd parallel_downloader
mix deps.get
```

## Usage

In order to fetch URL(s), simply add them as a parameter to `run.sh`, as following:

```sh
./run.sh ftp://1.2.3.4 http:// http://google.com:81 https://telnyx.com/ https://rafaelantunes.com.br http://google.com http://nxnxnxn.com www.google.com

21:00:20.761 [warn]  IGNORED ftp://1.2.3.4

21:00:20.762 [warn]  IGNORED http://

21:00:20.762 [warn]  IGNORED www.google.com

21:00:20.779 [warn]  GET http://nxnxnxn.com -> 13ms nxdomain

21:00:21.035 [info]  GET http://google.com -> 268ms 200

21:00:22.020 [info]  GET https://telnyx.com/ -> 1253ms 200

21:00:22.223 [info]  GET https://rafaelantunes.com.br -> 1457ms 200

21:00:22.778 [warn]  TIMEOUT http://google.com:81
```

You can run the test suite with `./test.sh`.

## Implementation Overview

The Downloader code can be found at the `ParallelDownload.Downloader` module. The `start/1` function is the entrypoint, from which we'll validate the URLs (rejecting the ones that are considered invalid, as described below) and proceed with the concurrent fetching of the valid URLs.

For each valid URL, `Stream.run/1` will spawn an Erlang process that will perform the GET request using the HTTPoison library as the HTTP client backend. We then handle the result and log the appropriate message.

You can see on the output below that even though we are making 5 requests, each one of them completed in the same second.

```
./run.sh https://google.com https://google.com https://google.com https://google.com https://google.com

20:06:01.578 [info]  GET https://google.com -> 530ms 200

20:06:01.578 [info]  GET https://google.com -> 531ms 200

20:06:01.584 [info]  GET https://google.com -> 538ms 200

20:06:01.589 [info]  GET https://google.com -> 542ms 200

20:06:01.589 [info]  GET https://google.com -> 543ms 200
```

The maximum number of downloads happening in parallel will be defined by `System.schedulers_online/0`, which defaults to the total number of threads in the system.

### Valid URLs

URLs are considered valid if they:

- contain the `http` or `https` scheme; and
- are parsed by `URI.parse/1`.

For the purposes of this exercise I am ignoring any non-HTTP scheme, like FTP or SSH.

### Testing

There are a couple of adjustments that were made to increase the testability of the code. They are:

1) Environment-specific HTTP client implementation

This allows us to mock the HTTP request and cover the different test cases without performing heavy, slow and unreliable side-effects.

2) Override of `start/1` parameters

This allows tests to specify a list of URLs (instead of relying on `System.argv/0`).

### URL redirection

If a redirection is requested by the server, we follow it and return the HTTP status code of the final destination.

