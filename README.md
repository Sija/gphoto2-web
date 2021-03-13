# gphoto2-web.cr [![CI](https://github.com/Sija/gphoto2-web.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/Sija/gphoto2-web.cr/actions/workflows/ci.yml) [![License](https://img.shields.io/github/license/Sija/gphoto2-web.cr.svg)](https://github.com/Sija/gphoto2-web.cr/blob/master/LICENSE)

REST web API for the [libgphoto2](http://www.gphoto.org/) library. You can use it to take pictures, previews (handy for implementing poor man's liveview feature), control/obtain various camera settings, and access connected camera's filesystem - all via JSON-based requests.

## Installation

- After cloning the repo you need to call `shards install` in order to obtain needed dependencies
- Next, execute `shards build` (possibly with `--production` flag) to build the binary
- You're ready to go! It's as easy as running `./bin/server` and checking the http://localhost:3000/cameras for list of detected cameras
- Passing `SENTRY_DSN` env var while builing/running will provide you with error reporting

## Usage

### Available endpoints

#### `/cameras`

- `GET /cameras`
- `POST /cameras/reload`

#### `/cameras/:id`

- `GET /cameras/:id`
- `GET /cameras/:id/capture[?delete=true]`
- `GET /cameras/:id/preview`
- `POST /cameras/:id/exit`

#### `/cameras/:id/config`

- `GET /cameras/:id/config[?flat=true]`
- `PATCH /cameras/:id/config`

#### `/cameras/:id/config/:widget`

- `GET /cameras/:id/config/:widget`
- `PATCH /cameras/:id/config/:widget`

#### `/cameras/:id/fs`

- `GET /cameras/:id/fs`
- `GET /cameras/:id/fs/*path`
- `DELETE /cameras/:id/fs/*path`

#### `/cameras/:id/blob`

- `GET /cameras/:id/blob/*filepath`
- `DELETE /cameras/:id/blob/*filepath`

#### `/cameras/:id/zip`

- `GET /cameras/:id/zip`
- `GET /cameras/:id/zip/*path`

## Development

- Pass `DEBUG=1` in `shards build` step to compile-in the debug support. Afterwards you can use it by passing `DEBUG=1` env variable when running the server (`DEBUG=1 ./bin/server`)

## Contributing

1. Fork it (<https://github.com/Sija/gphoto2-web.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Sija](https://github.com/Sija) Sijawusz Pur Rahnama - creator, maintainer
