# gphoto2-web [![CI](https://github.com/Sija/gphoto2-web/actions/workflows/ci.yml/badge.svg)](https://github.com/Sija/gphoto2-web/actions/workflows/ci.yml) [![License](https://img.shields.io/github/license/Sija/gphoto2-web.svg)](https://github.com/Sija/gphoto2-web/blob/master/LICENSE)

REST web API for the [libgphoto2](http://www.gphoto.org) library. You can use it to take pictures, previews (handy for implementing poor man's liveview feature), control/obtain various camera settings, and access connected camera's filesystem - all via JSON-based requests.

## Goals

- Providing a generic camera REST API
- Providing a feature parity with [libgphoto2](https://github.com/gphoto/libgphoto2) library
- Being a testbed for [gphoto2.cr](https://github.com/Sija/gphoto2.cr) shard
- Clean and readable code ✨
- Rock-solid stability 🪨
- High performance 🚀

## Non-Goals

- Including customizable business logic
- Including camera-specific features

## Features

- Camera detection
- Multiple cameras support
- Camera connection reloading
- Camera ability detection
- Image capture [^1]
- Live-view [^1]
- Configuration preview/modification [^1]
- File preview (incl. _raw_ camera formats) [^1]
- File download (in several formats [^2]) [^1]
- File removal [^1]
- Folder download as ZIP archive [^1]
- Folder removal [^1]
- Minimal dependencies

[^1]: Works only with supported cameras
[^2]: JPEG, WEBP, AVIF, PNG

## Setup

> [!TIP]
> Passing `SENTRY_DSN` env var while building/running will provide you with error reporting

- Run `shards install` in order to install required dependencies
- Next, execute `shards build [--release] [-Dpreview_mt]` to build the binary
- Now you're ready to go!
  - It's as easy as running `./bin/server` in your terminal
  - Checking the http://localhost:3000/cameras endpoint will give you a list of detected cameras

## Usage

### Available endpoints

#### `/cameras`

- `GET /cameras`

    Parameters:

    | name     | value  | description                        |
    | -------- | ------ | ---------------------------------- |
    | `reload` | `true` | Reloads the camera list beforehand |

#### `/cameras/:id`

- `GET /cameras/:id`
- `GET /cameras/:id/capture`

    Parameters:

    | name     | value  | description                     |
    | -------- | ------ | ------------------------------- |
    | `delete` | `true` | Deletes the image after capture |

- `GET /cameras/:id/preview`
- `GET /cameras/:id/exit`

#### `/cameras/:id/config`

- `GET /cameras/:id/config`

    Parameters:

    | name   | value  | description                                                     |
    | ------ | ------ | --------------------------------------------------------------- |
    | `flat` | `true` | Returns one-dimensional configuration map, keyed by widget name |

- `PATCH /cameras/:id/config`

    Example request:

    ```sh
    curl \
        -X PATCH \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d '{"whitebalance": "Automatic", "iso": 800, "f-number": "f/4.5"}' \
        "http://localhost:3000/cameras/5a337150-30ba-40fd-adc2-b9ffacdad188/config"
    ```

#### `/cameras/:id/config/:widget`

- `GET /cameras/:id/config/:widget`
- `PATCH /cameras/:id/config/:widget`

    Example request:

    ```sh
    curl \
        -X PATCH \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d '{"value": "Automatic"}' \
        "http://localhost:3000/cameras/5a337150-30ba-40fd-adc2-b9ffacdad188/config/whitebalance"
    ```

#### `/cameras/:id/fs`

- `GET /cameras/:id/fs`
- `GET /cameras/:id/fs/*path`
- `DELETE /cameras/:id/fs/*path`
- `PUT /cameras/:id/fs/*path`

    Example request:

    ```sh
    curl \
        -X PUT \
        -H "Accept: application/json" \
        "http://localhost:3000/cameras/5a337150-30ba-40fd-adc2-b9ffacdad188/fs/store_00010001/DCIM007"
    ```

#### `/cameras/:id/blob`

- `GET /cameras/:id/blob/*filepath`

    Parameters:

    | name       | value                                     | description                                                                                                                                           |
    | ---------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
    | `download` | `true`                                    | Makes the browser download the image instead of displaying it                                                                                         |
    | `format`   | `jpeg` / `webp` / `avif` / `png` / `auto` | Returns the image in a given format, `auto` chooses between the original format, if it's supported by the browser, and falls back to `jpeg` otherwise |
    | `width`    | *integer*                                 | Returns the image scaled down to the given width                                                                                                      |
    | `height`   | *integer*                                 | Returns the image scaled down to the given height                                                                                                     |

- `DELETE /cameras/:id/blob/*filepath`
- `PUT /cameras/:id/blob/*path`

    Example request:

    ```sh
    curl \
        -X PUT \
        -H "Accept: application/json" \
        -F file="@/path/to/file.jpg" \
        "http://localhost:3000/cameras/5a337150-30ba-40fd-adc2-b9ffacdad188/blob/store_00010001/DCIM007/IMG_0001.jpg"
    ```

#### `/cameras/:id/zip`

- `GET /cameras/:id/zip`
- `GET /cameras/:id/zip/*path`

## Development

> [!TIP]
> You can use a smartphone for basic development and testing.

- Pass `DEBUG=1` in `shards build` step to compile-in the debug support. Afterwards you can use it by passing `DEBUG=1` env variable when running the server (`DEBUG=1 ./bin/server`)

## Contributing

1. Fork it (<https://github.com/Sija/gphoto2-web/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Sija](https://github.com/Sija) Sijawusz Pur Rahnama - creator, maintainer
