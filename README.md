# gphoto2-web [![CI](https://github.com/Sija/gphoto2-web/actions/workflows/ci.yml/badge.svg)](https://github.com/Sija/gphoto2-web/actions/workflows/ci.yml) [![License](https://img.shields.io/github/license/Sija/gphoto2-web.svg)](https://github.com/Sija/gphoto2-web/blob/master/LICENSE)

REST web API for the [libgphoto2](http://www.gphoto.org/) library. You can use it to take pictures, previews (handy for implementing poor man's liveview feature), control/obtain various camera settings, and access connected camera's filesystem - all via JSON-based requests.

## Installation

- After cloning the repo you need to call `shards install` in order to obtain needed dependencies
- Next, execute `shards build` (possibly with `--production` flag) to build the binary
- You're ready to go! It's as easy as running `./bin/server` and checking the http://localhost:3000/cameras for list of detected cameras
- Passing `SENTRY_DSN` env var while building/running will provide you with error reporting

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

#### `/cameras/:id/zip`

- `GET /cameras/:id/zip`
- `GET /cameras/:id/zip/*path`

## Development

- Pass `DEBUG=1` in `shards build` step to compile-in the debug support. Afterwards you can use it by passing `DEBUG=1` env variable when running the server (`DEBUG=1 ./bin/server`)

## Contributing

1. Fork it (<https://github.com/Sija/gphoto2-web/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Sija](https://github.com/Sija) Sijawusz Pur Rahnama - creator, maintainer
